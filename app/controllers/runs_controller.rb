class RunsController < ApplicationController
  before_action :authenticate_user!, :only => [:create, :index, :show]

  def index
    @runs = current_user.runs
  end

  def show
    @run = Run.find(params[:id])
    @algorithm = @run.algorithm
    @image = @run.image
    @images = Image.where(:generated_by_run_id=>@run.id).order('id desc')
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

  def annotation_form
    @image = Image.find(params[:image_id])
    @run = current_user.runs.new
    render partial: 'annotation_form'
  end


  private
    def run_params
    	params.require(:run).permit(:image_id, :algorithm_id, :parameters, :annotation_id)
  	end
end
