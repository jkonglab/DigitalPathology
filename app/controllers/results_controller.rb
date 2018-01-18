class ResultsController < ApplicationController
	respond_to :html, :json

	def exclude
		result = current_user.results.find(params[:id])
		result.update_attributes!(:exclude=>true) if !result.blank?
    	respond_with(result)
	end

	def include
		result = current_user.results.find(params[:id])
		result.update_attributes!(:exclude=>false) if !result.blank?
    	respond_with(result)
    end

end