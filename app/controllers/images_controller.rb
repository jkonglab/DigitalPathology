class ImagesController < ApplicationController
    
  def index
      @images = Image.all
  end  
  
  def new
    @image = Image.new
  end

  def create
    uploaded_io = params[:file]
    original_filename = uploaded_io.original_filename #myfile.svs
    image = generate_new_image(original_filename)

    File.open(Rails.root.join('python', 'data', image.upload_file_name), 'wb') do |file|
        file.write(uploaded_io.read)
    end

    ConversionWorker.perform_async(image.id)

    redirect_to images_path, notice: 'Image created, please wait for it to be processed.'
  end

  def show
      @image = Image.find(params[:id])
      @annotation = Annotation.new
      @imageJSON = ClinicalDatum.new
      @clinical = ClinicalDatum.where(image_id: params[:id])
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
