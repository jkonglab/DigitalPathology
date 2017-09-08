class RunsController < ApplicationController
  before_action :authenticate_user!, :only => [:create, :index, :show]

  def index
    @runs = current_user.runs
  end

  def show
    @run = Run.find(params[:id])
    @image = @run.image
    @annotation = @run.annotation
    @results = @run.results
    @results_svg = @results.pluck(:svg_data)
  end

  def create
	@run = current_user.runs.new(run_params)
  algorithm = Algorithm.find(@run.algorithm_id)
  algorithm_parameters = algorithm.parameters.sort_by { |k| k["order"] }
  run_parameters = []

  algorithm_parameters.each do |algorithm_parameter|
    parameter_value = params["parameters"][algorithm_parameter["key"]]
    if algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["numeric"]
      parameter_value = parameter_value.to_i
    elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["boolean"]
      parameter_value = parameter_value == "1"
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


  private
    def run_params
    	params.require(:run).permit(:image_id, :algorithm_id, :parameters, :annotation_id)
  	end
end
