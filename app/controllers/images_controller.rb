class ImagesController < ApplicationController
  before_action :authenticate_user!, :only => [:create, :new]
  before_action :set_image, :only => [:show, :add_single_clinical_data, :add_upload_clinical_data, :get_slice]
  respond_to :json, only: [:get_slice]

    
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
    uploaded_io = params[:file]
    original_filename = uploaded_io.original_filename #myfile.svs
    image = Image.create_new_image(original_filename, current_user.id)

    File.open(Rails.root.join('public', Rails.application.config.data_directory, image.upload_file_name), 'wb') do |file|
        file.write(uploaded_io.read)
    end

    ConversionWorker.perform_async(image.id)

    redirect_to images_path, notice: 'Image created, please wait for it to be processed.'
  end

  def show
    @run = @image.runs.new
    @algorithm = @image.threed? && @image.parent_id.blank? ? Algorithm.all : Algorithm.where('output_type NOT IN (?)', Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"])
    @annotation = Annotation.new
    @clinical_data = @image.clinical_data || {}
    @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
    @slice = @image.threed? && @image.parent_id.blank? ? @slices.first : @image
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
    image_ids = params['image_ids']
    @images = current_user.images.where('images.id IN (?)', image_ids)
    
    if @images.length == 1
      image = @images[0]
      images = Image.where('(images.id IN (?) or parent_id IN (?))', image.id, image.id)
      images.delete_all
      return redirect_to my_images_images_path, notice: "Image #{image.title} deleted"
    elsif @images.length == 0
      return redirect_to my_images_images_path, notice: 'No valid images selected for deletion'
    end
  end

  def delete
    image_ids = params['image_ids']
    @images = current_user.images.where('images.id IN (?)', image_ids)
    length = @images.length
    @images.delete_all
    return redirect_to my_images_images_path, notice: "#{length} images deleted"
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
      :path => first_image.path,
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

  private

  def set_image
    @image = Image.find(params[:id])
  end
end
