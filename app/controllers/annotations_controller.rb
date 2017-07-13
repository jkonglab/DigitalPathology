class AnnotationsController < ApplicationController
  before_action :authenticate_user!, :only => [:create]

  def create
    data = params[:data].blank? ? {} : JSON.parse(params[:data])
    image_id = params[:image_id]
    label = params[:label]
    @annotation = Annotation.create(:data=> data, :image_id=>image_id, :label=> label)

    respond_to do |format|
    	format.html { redirect_to Image.find(image_id) }
    	format.json  { render :json => @annotation }
  	end
  end

end
