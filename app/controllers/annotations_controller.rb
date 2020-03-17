class AnnotationsController < ApplicationController
  before_action :authenticate_user!, :only => [:create]

  def create
    image = Image.find(params[:image_id])
    @annotation = image.annotations.new

    if image.threed? && image.parent_id.blank?
      image = Image.where(:parent_id => image.id).order('slice_order asc')[0]
    end

    data = params[:data].blank? ? {} : JSON.parse(params[:data])
    width = (params[:width].to_f / 100) * image.width
    height = (params[:height].to_f / 100) * image.height
    x_point = (params[:x].to_f / 100) * image.width
    y_point = (params[:y].to_f / 100) * image.height
    
    annotation_class  = params[:annotation_class]
    annotation_type  = params[:annotation_type]
    @annotation.update_attributes({
      :user_id=>current_user.id,
      :data=> data, 
      :label=>params[:label], 
      :x_point=>x_point,
      :y_point=>y_point,
      :width=>width,
      :height=>height,
      :annotation_class=>annotation_class,
      :annotation_type=>annotation_type
      })

    render :partial => 'images/annotation_row.html.erb', :locals => { :annotation=>@annotation }
  end

  def destroy
    @annotation = current_user.annotations.where(:id=>params[:id])
    if @annotation.count > 0
      image_id = @annotation.first.image_id
      @annotation.first.delete

      respond_to do |format|
        format.html { redirect_to Image.find(image_id), notice: "Annotation Deleted" }
      end
    else
      redirect_back fallback_location: root_path, notice: "You cannot delete those annotations because you lack permissions to do so."
    end
  end

  def delete_selected
    annotation_ids = params[:annotation_ids]
    unless annotation_ids.nil?
        length = annotation_ids.length
        image_id = 0
        annotation_ids.each do |annotation_id|
            annotation = current_user.annotations.where(:id=>annotation_id)
            image_id = annotation.first.image_id
            annotation.first.delete
        end
        respond_to do |format|
            format.html { redirect_to Image.find(image_id), notice: "#{length} Annotations Deleted" }
        end
    end
  end

end
