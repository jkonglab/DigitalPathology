class RunsController < ApplicationController
  respond_to :html, :json
  before_action :authenticate_user!, :only => [:create, :index, :show]

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
    @results = @run.results.order('id asc');
    @results_data = @results.pluck(:svg_data, :id, :exclude)
  end

  def create
  	@run = current_user.runs.new(run_params)
    image = Image.find(@run.image_id)
    if image.threed? && image.parent_id.blank?
      @run.image_id = Image.where(:parent_id => image.id).order('slice_order asc')[0].id
    end

    algorithm = Algorithm.find(@run.algorithm_id)
    annotation = Annotation.find(@run.annotation_id)
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
  		TilingWorker.perform_async(@run.id)
      redirect_to @run, notice: 'New analysis created, please wait for it to finish running.'
  	end
  end

  def download_results
    @run = Run.find(params[:id])
    @results = @run.results.where('exclude IS NOT true').order('id asc')
    @algorithm = @run.algorithm
    output = []

    @results.each do |result|
      result_hash = {}
      result_hash["tile_coordinate"] = [result.tile_x, result.tile_y]
      result_hash["local_coordinates"] = result.raw_data
      result_hash["tile_size"] = result.run.tile_size
      absolute_data = result.raw_data.deep_dup

      if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
        absolute_data.map{ |data_item|
          data_item[0] += result.tile_x
          data_item[1] += result.tile_y
        }
      elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
        absolute_data[0] += result.tile_x
        absolute_data[1] += result.tile_y
      end

      result_hash["absolute_coordinates"] = absolute_data

      output << result_hash
    end

    send_data output.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=results.json"
  end

  def annotation_form
    @image = Image.find(params[:image_id])
    @run = current_user.runs.new
    render partial: 'annotation_form'
  end


  private
    def run_params
    	params.require(:run).permit(:image_id, :algorithm_id, :parameters, :annotation_id, :tile_size)
  	end
end
