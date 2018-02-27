class ImagesController < ApplicationController
  include ApplicationHelper
  before_action :set_current_user
  before_action :authenticate_user!, :except => [:index, :show]
  before_action :set_image_validated, :only => [:show, :add_single_clinical_data, :add_upload_clinical_data, :get_slice, :import_annotations]
  before_action :set_images_validated, :only =>[:confirm_delete, :delete, :make_public, :make_private, :confirm_share, :share]
  respond_to :json, only: [:get_slice]


  autocomplete :user, :email
    
  def index
    query_params = params['q'] || {}
    query_builder = QueryBuilder.new(query_params)
    @q = query_builder.to_ransack(Image.where(:visibility => Image::VISIBILITY_PUBLIC, :parent_id=>nil))
    @images= @q.result.reorder(query_builder.sort_order)
  end  
  
  def new
    @images = Image.new
  end

  def create
    @image = Image.create(image_params)
    @image.title = @image.file_file_name.gsub('_', ' ')
    @image.image_type = Image::IMAGE_TYPE_TWOD
    UserImageOwnership.create!(
      :user_id=> current_user.id,:image_id=> @image.id)
    @image.save
    ConversionWorker.perform_async(@image.id)
    redirect_to my_images_images_path, notice: 'Image created, please wait for it to be processed.' and return
  end

  def show
    @run = @image.runs.new
    @algorithm = @image.threed? && @image.parent_id.blank? ? Algorithm.all : Algorithm.where('output_type NOT IN (?)', Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"])
    @annotation = Annotation.new
    @annotations = @image.visibility == Image::VISIBILITY_PRIVATE ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    @clinical_data = @image.clinical_data || {}
    @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
    @image_shown = @image.threed? && @image.parent_id.blank? ? @slices.first : @image
  end

  def get_slice
    @slice = Image.where(:parent_id => @image.id).order('slice_order asc')[params[:slice].to_i]
    respond_with @slice
  end

  def my_images
    query_params = params['q'] || {}
    query_builder = QueryBuilder.new(query_params)
    @q = query_builder.to_ransack(current_user.images.where(:parent_id=>nil))
    @images= @q.result.reorder(query_builder.sort_order)
  end

  def confirm_delete
    if @images.length == 1
      image = @images[0]
      images = Image.where('(images.id IN (?) or parent_id IN (?))', image.id, image.id)
      images.destroy_all
      return redirect_to my_images_images_path, notice: "Image #{image.title} deleted"
    end
  end

  def delete
    length = @images.length
    @images.destroy_all
    return redirect_to my_images_images_path, notice: "#{length} images deleted"
  end

  def confirm_share
  end

  def share
    user = User.where(:email => params[:user][:email])
    length = @images.length
    if user.count > 0
      @images.each do |image|
        UserImageOwnership.find_or_create_by!(:user_id=>user[0].id, :image_id=>image.id)
      end
      return redirect_to my_images_images_path, notice: "#{length} images shared with #{user[0].email}"
    else
      redirect_to my_images_images_path, alert: 'Could not find user to share with'
    end
  end

  def make_public
    @images.update_all(:visibility=>Image::VISIBILITY_PUBLIC)
    redirect_to my_images_images_path, notice: "#{@images.count} images made public"
  end 

  def make_private
    @images.update_all(:visibility=>Image::VISIBILITY_PRIVATE)
  end

  def confirm_convert_3d
    image_ids = params['image_ids']
    @images = current_user.images.where('image_type != ? AND images.id IN (?)', Image::IMAGE_TYPE_THREED, image_ids).sort_by{|image| image.title}
    if @images.length < 1
      return redirect_to my_images_images_path, alert: 'Volume could not be created because all selected images are already attached to a 3D volume.'
    end
  end

  def convert_3d
    image_ids = params['image_ids']
    i = 0
    first_image = nil
    image_ids.each do |id|
      image = current_user.images.where(:parent_id => nil).find(id)
      if image
        first_image = first_image || image
        image.update_attributes!(:slice_order => i, :image_type => Image::IMAGE_TYPE_THREED)
        i += 1
      end
    end

    parent_image = current_user.images.create!(
      :title => '3D Volume: ' + first_image.title, 
      :image_type => Image::IMAGE_TYPE_THREED, 
      :visibility => first_image.visibility,
      :processing => 0,
      :file_file_name => first_image.file_file_name,
      :file_content_type => first_image.file_content_type,
      :file_file_size => first_image.file_file_size,
      :file_updated_at => first_image.file_updated_at,
      :clinical_data => first_image.clinical_data,
      :generated_by_run_id => first_image.generated_by_run_id
    )

    images = Image.where('id in (?)', image_ids)
    images.update_all(:parent_id=> parent_image.id)
    images.update_all(:visibility=> parent_image.visibility)
    redirect_to my_images_images_path, notice: 'Images converted into 3D volume'
  end

  def add_single_clinical_data
    key = params[:meta_key]
    value = params[:meta_value]
    data = @image.clinical_data || {}
    data[key] = value
    @image.update_attributes!(:clinical_data=>data)
    redirect_to :back
  end

  def add_upload_clinical_data
    data = @image.clinical_data || {}
    json_file = params[:image][:upload].read
    begin
      json_hash = JSON.parse(json_file)
      json_hash.each do |key,value|
        data[key] = value
      end
      @image.update_attributes!(:clinical_data=>data)
      redirect_to :back
    rescue JSON::ParserError
      redirect_to :back, alert: 'Error parsing JSON file.  Please validate the file using a linter and make sure keys are double quoted!'
    end
  end

  def import_annotations
    json_file = params[:image][:upload].read
    begin
      json = JSON.parse(json_file)
      json.each do |annotation_hash|
        annotation = @image.annotations.new
        contour = annotation_hash["absolute_coordinates"]
        contour_svg = convert_to_svg_contour(contour, @image)
        annotation.user_id = current_user.id
        annotation.update_attributes({
          :data=>contour_svg,
          :label=>annotation_hash["name"]
          })
        annotation.save!
      end
      redirect_to :back, notice: "{#json.length} annotations added successfully."
    rescue JSON::ParserError
      redirect_to :back, alert: 'Error parsing JSON file.  Please validate the file using a linter and make sure keys are double quoted!'
    end
  end

  private
  def image_params
    params.require(:image).permit(:file)
  end

  def set_image_validated
    @image = Image.find(params[:id])
    if @image.visibility == Image::VISIBILITY_PRIVATE && !(@image.users.pluck(:id).include?(current_user.id))
      redirect_to images_path, alert: 'You do not have permission to access or edit this image'
    end
  end

  def set_images_validated
    image_ids = params['image_ids']
    @images = current_user.images.where('images.id IN (?)', image_ids)
    if @images.length < 1
      redirect_to images_path, alert: 'You do not have permission to edit any of these images'
    end      
  end


end
