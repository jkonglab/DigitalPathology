class AlgorithmsController < ApplicationController

	def parameter_form
		image = Image.find(params[:image_id])
		@run = image.runs.new
		@algorithm = Algorithm.find(params[:algorithm_id])

		render partial: 'parameter_form'
	end

end