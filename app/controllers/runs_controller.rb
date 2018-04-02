class RunsController < ApplicationController
  respond_to :html, :json
  before_action :authenticate_user!, :only => [:create, :index, :show, :get_results]
  before_action :set_runs_validated, :only =>[:confirm_delete, :delete]
  before_action :set_run_validated, :only => [:show, :get_results, :download_results]

  def index
    @runs = current_user.runs.order('id desc')
  end

  def show
    @run = Run.find(params[:id])
    @algorithm = @run.algorithm
    @image = @run.image
    @slices = Image.where('generated_by_run_id IN (?) AND (image_type = ? OR parent_id IS NOT NULL)', @run.id, Image::IMAGE_TYPE_TWOD).order('id desc')
    @threed_volume = Image.where('generated_by_run_id IN (?) AND image_type = ? AND parent_id IS NULL', @run.id, Image::IMAGE_TYPE_THREED).first
    @annotation = @run.annotation
    
    @results = @algorithm.multioutput ? @run.results.where(:output_key=>@algorithm.multioutput_options[0]["output_key"]).order('id asc') : @run.results.order('id asc')

    if @results.count < 10000
      @results_data = @results.pluck(:svg_data, :id, :exclude)
    else
      @results = [0]
      @results_data = [0]
    end

    if @algorithm.multioutput
      @numerical_result_hash = {}
      @algorithm.multioutput_options.each do |option|
        key = option["output_key"]
        if option["output_type"] == Algorithm::OUTPUT_TYPE_LOOKUP["scalar"]
          @numerical_result_hash[key.to_sym] = @run.results.where(:output_key=>key).pluck(:raw_data).sum
        elsif option["output_type"] == Algorithm::OUTPUT_TYPE_LOOKUP["percentage"]
          results = @run.results.where(:output_key=>key).pluck(:raw_data)
          @numerical_result_hash[key.to_sym] = results.length > 0 ? (results.sum / results.length) : 0
        end
      end
    end

  end

  def get_results
    @run = Run.find(params[:id])
    @algorithm = @run.algorithm
    @results = @run.results.where('tile_x >= ? AND tile_x <= ? AND tile_y >= ? AND tile_y <= ?', params['x'].to_f - @run.tile_size, (params['x'].to_f + params["width"].to_f), params['y'].to_f - @run.tile_size, (params['y'].to_f + params["height"].to_f))

    if params["key"]
      @results = @results.where(:output_key=>params["key"]).order('id asc')
    elsif @algorithm.multioutput 
      @results = @results.where(:output_key=>@algorithm.multioutput_options[0]["output_key"]).order('id asc')
    end

    if @results.count < 10000
      @results_data = @results.pluck(:svg_data, :id, :exclude)
    else
      @results = [0]
      @results_data = [0]
    end
    respond_with @results_data.to_json
  end

  def create
  	@run = current_user.runs.new(run_params)
    image = Image.find(@run.image_id)
    if image.threed? && image.parent_id.blank?
      @run.image_id = Image.where(:parent_id => image.id).order('slice_order asc')[0].id
    end
    
    algorithm = Algorithm.find(@run.algorithm_id)
    if algorithm.name == 'high_low_registration'
      @run.tile_size = 0
    end
    if @run.annotation_id.blank?
      @run.update_attributes!(:annotation_id => 0)
      annotation = image.annotations.new(:label=> 'Whole Slide')
    else
      annotation = Annotation.find(@run.annotation_id)
    end
    algorithm_parameters = algorithm.parameters.sort_by { |k| k["order"] }
    run_parameters = []

    algorithm_parameters.each do |algorithm_parameter|
      if algorithm_parameter["hard_coded"]
        parameter_value = algorithm_parameter["default_value"]
      elsif algorithm_parameter["annotation_derived"]
        parameter_value = annotation[algorithm_parameter["annotation_key"]]
      else
        parameter_value = params["parameters"][algorithm_parameter["key"]]
        if algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["numeric"]
          parameter_value = parameter_value.to_i
        elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["boolean"]
          parameter_value = parameter_value == "1"
        elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["array"]
          if !parameter_value.blank?
            begin
              parameter_value = JSON.parse(parameter_value)
            rescue JSON::ParserError
                redirect_to image, alert: 'Could not parse your inputted array in run parameters.  Please make sure your arrays are comma separated and contained within square brackets [like, this]'
                return
            end
          end
        end
      end
      run_parameters << parameter_value
    end

  	@run.parameters = run_parameters

  	if @run.save
      Sidekiq::Client.push('queue' => 'user_tiling_queue_' + @run.user_id.to_s, 'class' =>  TilingWorker, 'args' => [@run.id])
      redirect_to @run, notice: 'New analysis created, please wait for it to finish running.'
  	end
  end

  def confirm_delete
    if @runs.length == 1
      run = @runs[0]
      run.destroy
      return redirect_to runs_path, notice: "Run #{run.id} deleted"
    end
  end

  def delete
    length = @runs.length
    @runs.destroy_all
    return redirect_to runs_path, notice: "#{length} runs deleted"
  end

  def download_results
    @run = Run.find(params[:id])
    @results = @run.results.where('exclude IS NOT true').order('output_key asc, id asc')
    @algorithm = @run.algorithm
    output = []

    @results.each do |result|
      result_hash = {}
      result_hash["output_key"] = result.output_key
      result_hash["tile_coordinate"] = [result.tile_x, result.tile_y]
      result_hash["local_coordinates"] = result.raw_data
      result_hash["tile_size"] = result.run.tile_size
      result_hash["raw_data"] = result.raw_data
      absolute_data = result.raw_data.deep_dup
      output_type = result.output_type || @algorithm.output_type

      if output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
        absolute_data.map{ |data_item|
          data_item[0] += result.tile_x
          data_item[1] += result.tile_y
        }
        result_hash["absolute_coordinates"] = absolute_data
      elsif output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
        absolute_data[0] += result.tile_x
        absolute_data[1] += result.tile_y
        result_hash["absolute_coordinates"] = absolute_data
      end

      output << result_hash
    end

    send_data output.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=results.json"
  end

  def annotation_form
    @image = Image.find(params[:image_id])
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    @run = current_user.runs.new
    render partial: 'annotation_form'
  end


  private
    def run_params
    	params.require(:run).permit(:image_id, :algorithm_id, :parameters, :annotation_id, :tile_size)
  	end

    def set_run_validated
      @run = Run.find(params[:id])
      if current_user.id != @run.user_id
        redirect_to runs_path, alert: 'You do not have permission to access or edit this image'
      end
    end

    def set_runs_validated
      run_ids = params['run_ids']
      if !run_ids
        redirect_to runs_path, alert: 'No runs selected'
      else
        @runs = current_user.runs.where('runs.id IN (?)', run_ids)
        if @runs.length < 1
          redirect_to runs_path, alert: 'No runs selected or you may lack permission to access these runs'
        end
      end     
    end
end
