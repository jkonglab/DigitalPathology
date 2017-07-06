class AnnotationsController < ApplicationController

  def create
    data = params[:data].blank? ? {} : params[:data]
    data[0][1]["d"] = data[0][1]["d"] + 'Z'
    byebug
    image_id = params[:image_id]
    label = params[:label]
    @annotation = Annotation.create(:data=> data, :image_id=>image_id, :label=> label)

    respond_to do |format|
    	format.html { redirect_to Image.find(image_id) }
    	format.json  { render :json => @annotation }
  	end
  end

end
