class AnnotationsController < ApplicationController

  def create
    data = params[:annotation][:data].blank? ? {} : params[:annotation][:data]
    image_id = params[:annotation][:image_id]
    Annotation.create(:data=> data, :image_id=>image_id)
    redirect_to Image.find(image_id)
  end

end
