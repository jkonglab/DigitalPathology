class ImagesController < ApplicationController
  before_action :authenticate_user!, :only => [:create, :new]
    
  def index
      @images = Image.all.order('id asc')
  end  
  
  def new
    @image = Image.new
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
    @image = Image.find(params[:id])
    @run = @image.runs.new
    @annotation = Annotation.new
    @clinical = ClinicalDatum.where(image_id: params[:id])
    @image_json = ClinicalDatum.new
  end

  private

  def generate_new_image(original_filename)
    image_suffix =  original_filename.split('.')[-1]
    image_title = original_filename.split('.'+image_suffix)[0]
    image_unique_id = Image.last ? Image.last.id + 1 : 2

    new_file_name = image_title + '-' + image_unique_id.to_s + '.' + image_suffix
    return Image.create(:title => image_title, :upload_file_name => new_file_name)
  end
  
end
