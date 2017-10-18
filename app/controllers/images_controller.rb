class ImagesController < ApplicationController
  before_action :authenticate_user!, :only => [:create, :new]
  before_action :set_image, :only => [:show, :add_single_clinical_data, :add_upload_clinical_data]
    
  def index
    query_params = params['q'] || {}
    query_builder = QueryBuilder.new(query_params)
    @q = query_builder.to_ransack
    @images= @q.result.reorder(query_builder.sort_order)
  end  
  
  def new
    @images = Image.new
  end

  def create
    uploaded_io = params[:file]
    original_filename = uploaded_io.original_filename #myfile.svs
    image = generate_new_image(original_filename)

    File.open(Rails.root.join('public', Rails.application.config.data_directory, image.upload_file_name), 'wb') do |file|
        file.write(uploaded_io.read)
    end

    ConversionWorker.perform_async(image.id)

    redirect_to images_path, notice: 'Image created, please wait for it to be processed.'
  end

  def show
    @run = @image.runs.new
    @annotation = Annotation.new
    @clinical_data = @image.clinical_data || {}
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

  def generate_new_image(original_filename)
    image_suffix =  original_filename.split('.')[-1]
    image_title = original_filename.split('.'+image_suffix)[0]
    image_unique_id = Image.last ? Image.last.id + 1 : 2

    new_file_name = image_title + '-' + image_unique_id.to_s + '.' + image_suffix
    return Image.create(:title => image_title, :upload_file_name => new_file_name)
  end
  

  def set_image
    @image = Image.find(params[:id])
  end
end
