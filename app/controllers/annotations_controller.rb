class AnnotationsController < ApplicationController
  before_action :authenticate_user!, :only => [:create]

  def create
    image = Image.find(params[:image_id])

    if image.threed? && image.parent_id.blank?
      image = Image.where(:parent_id => image.id).order('slice_order asc')[0]
    end

    data = params[:data].blank? ? {} : JSON.parse(params[:data])
    width = (params[:width].to_f / 100) * image.width
    height = (params[:height].to_f / 100) * image.height
    x_point = (params[:x].to_f / 100) * image.width
    y_point = (params[:y].to_f / 100) * image.height
    @annotation = Annotation.create(
      :user_id => current_user.id,
      :data=> data, 
      :image_id=>params[:image_id], 
      :label=>params[:label], 
      :x_point=>x_point,
      :y_point=>y_point,
      :width=>width,
      :height=>height)

    respond_to do |format|
    	format.html { redirect_to Image.find(image_id) }
    	format.json  { render :json => @annotation }
  	end
  end

end
