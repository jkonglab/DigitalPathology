class RunsController < ApplicationController
  before_action :authenticate_user!, :only => [:create, :index, :show]

  def index
    @runs = current_user.runs
  end

  def show
    @run = Run.find(params[:id])
    @algorithm = @run.algorithm
    @image = @run.image
    @slices = Image.where('generated_by_run_id IN (?) AND (image_type = ? OR parent_id IS NOT NULL)', @run.id, Image::IMAGE_TYPE_TWOD).order('id desc')
    @threed_volume = Image.where('generated_by_run_id IN (?) AND image_type = ? AND parent_id IS NULL', @run.id, Image::IMAGE_TYPE_THREED).first
    @annotation = @run.annotation
    @results = @run.results
    @results_svg = @results.pluck(:svg_data)
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
        end
      end
      run_parameters << parameter_value
    end

  	@run.parameters = run_parameters

  	if @run.save
  		TilingWorker.perform_async(@run.id)
  		respond_to do |format|
          	format.html { redirect_to @run, notice: 'New analysis created, please wait for it to finish running.' }
          	format.json { render :show, status: :ok, location: @run }
      	end
  	end
  end

  def download_results
    @run = Run.find(params[:id])
    @results = @run.results
    @algorithm = @run.algorithm
    output = []

    @results.each do |result|
      raw_data = result.raw_data

      if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
        raw_data.map{ |data_item|
          data_item[0] += result.tile_x
          data_item[1] += result.tile_y
        }
      elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
        raw_data[0] += result.tile_x
        raw_data[1] += result.tile_y
      end

      output << raw_data
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
