class ImagesController < ApplicationController
  include ApplicationHelper
  before_action :set_current_user
  before_action :authenticate_user!, :except => [:index, :show]
  before_action :set_image_validated, :only => [:show_3d, :download_annotations, :show, :add_single_clinical_data, :add_upload_clinical_data, :get_slice, :import_annotations]
  before_action :set_images_validated, :only =>[:convert_3d, :confirm_convert_3d, :confirm_delete, :delete, :confirm_move, :move]
  respond_to :json, only: [:get_slice]

  autocomplete :user, :email 
  
  def new
    @images = Image.new
    @project = Project.find(params[:project_id])
  end

  

  def create
    if !current_user.projects.pluck(:id).include?(params['project_id'].to_i)
      render :json =>  {error: 'You do not have permission to upload images to this project'}, :status=> 422 and return
    else
      @image = Image.create(image_params)
      @image.project_id = params['project_id']
      @image.title = @image.file_file_name.gsub('_', ' ')
      @image.image_type = Image::IMAGE_TYPE_TWOD
      @image.save
      Sidekiq::Client.push('queue' => 'user_conversion_queue_' + current_user.id.to_s, 'class' =>  ConversionWorker, 'args' => [@image.id, current_user.id])
      redirect_to @image.project, notice: 'Image created, please wait for it to be processed'
    end
  end

  def show
    @run = @image.runs.new
    @algorithm = @image.threed? && @image.parent_id.blank? ? Algorithm.all : Algorithm.where('input_type NOT IN (?)', Algorithm::INPUT_TYPE_LOOKUP["3D"])
    @annotation = Annotation.new
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    @clinical_data = @image.clinical_data || {}
    @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
    default_slice = (@slices.length.to_f/2).ceil(0)
    @image_shown = @image.threed? && @image.parent_id.blank? ? @slices[default_slice] : @image
    @tilesizes = []
    minsize = @image.height > @image.width ? @image.width : @image.height
    [128,256,512,1024,2048].each do |size|
    	if minsize > size
        	@tilesizes << size
        end
    end	
  end

  def show_3d
    if @image.threed? && @image.parent_id.blank?
      @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
    else
      redirect_to @image, notice: 'Image is not a 3D volume and cannot be viewed in 3D space'
    end
  end

  def get_slice
    @slice = Image.where(:parent_id => @image.id).order('slice_order asc')[params[:slice].to_i]
    respond_with @slice
  end

  def confirm_delete
    if @images.length == 1
      image = @images[0]
      project = image.project
      file_folder = File.expand_path("..", File.dirname(image.file.path))
      image.destroy
      FileUtils.rm_rf(file_folder)
      return redirect_to project, notice: "Image #{image.title} deleted"
    end
  end

  def confirm_move
  end

  def move
    @images.update_all(:project_id=>params[:image][:project_id])
    redirect_to project_path(params[:image][:project_id]), notice: "#{@images.length} image(s) moved"
  end

  def delete
    length = @images.length
    project = @images.first.project
    @images.each do |image|
	file_folder = File.expand_path("..", File.dirname(image.file.path))
	image.destroy
        FileUtils.rm_rf(file_folder)
    end
	#@images.destroy_all
    return redirect_to project, notice: "#{length} images deleted"
  end

  def confirm_convert_3d
    @images = @images.order('title asc')
    if @images.length < 1
      return redirect_to @images.first.project, alert: 'Volume could not be created because all selected images are already attached to a 3D volume.'
    end
  end

  def convert_3d
    i = 1
    first_image = nil
    params['image_ids'].each do |id|
      image = Image.find(id.to_i)
      if image
        first_image = first_image || image
        image.update_attributes!(:slice_order => i, :image_type => Image::IMAGE_TYPE_THREED)
        i += 1
      end
    end

    parent_image = Image.create!(
      :title => '3D Volume: ' + first_image.title, 
      :image_type => Image::IMAGE_TYPE_THREED, 
      :visibility => first_image.visibility,
      :processing => false,
      :complete => true,
      :file_file_name => first_image.file_file_name,
      :file_content_type => first_image.file_content_type,
      :file_file_size => first_image.file_file_size,
      :file_updated_at => first_image.file_updated_at,
      :clinical_data => first_image.clinical_data,
      :generated_by_run_id => first_image.generated_by_run_id,
      :project_id => first_image.project_id,
      :height => first_image.height,
      :width => first_image.width
    )

    @images.update_all(:parent_id=> parent_image.id)
    @images.update_all(:visibility=> parent_image.visibility)
    redirect_to @images.first.project, notice: 'Images converted into 3D volume'
  end

  def add_single_clinical_data
    key = params[:meta_key]
    value = params[:meta_value]
    data = @image.clinical_data || {}
    data[key] = value
    @image.update_attributes!(:clinical_data=>data)
    redirect_to @image
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
      redirect_to @image
    rescue JSON::ParserError
      redirect_to @image, alert: 'Error parsing JSON file.  Please validate the file using a linter and make sure keys are double quoted!'
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
          :data=>[contour_svg],
          :label=>annotation_hash["name"]
          })
        annotation.save!
      end
      redirect_to @image, notice: "#{json.length} annotations added successfully."
    rescue JSON::ParserError
      redirect_to @image, alert: 'Error parsing JSON file.  Please validate the file using a linter and make sure keys are double quoted!'
    end
  end

  def download_annotations
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    output = []

    @annotations.each do |annotation|
      result_hash = {}
      result_hash["name"] = annotation.label
      result_hash["tile_coordinate"] = [annotation.x_point, annotation.y_point]
      result_hash["width"] = annotation.width
      result_hash["height"] = annotation.height
      points = []
      annotation_points = annotation.data[0][1]["d"].split("M")[1].split("Z")[0].split(" L")
      annotation_points.each do |point|
        puts point
        point_array = point.split(' ')
        points << [(((point_array[0].to_f)*@image.width)/100).to_i, (((point_array[1].to_f)*@image.height)/100).to_i]
      end

      result_hash["absolute_coordinates"] = points

      output << result_hash
    end

    send_data output.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=#{@image.title.split('.')[0]}_annotations.json"
  end

  private
  def image_params
    params.permit(:project_id)
    params.require(:image).permit(:file, :project_id)
  end

  def set_image_validated
    @image = Image.find(params[:id])
    if @image.hidden? && !(@image.project.users.pluck(:id).include?(current_user.id)) && !current_user.subadmin?
      redirect_to my_projects_path, alert: 'You do not have permission to access or edit this image'
    end
  end

  def set_images_validated
    image_ids = params['image_ids']
    if !image_ids
      redirect_back(fallback_url: my_projects_path, alert: 'No images selected')
    else
      project_ids = current_user.projects.pluck(:id)
      @images = !current_user.subadmin? ? Image.where('images.id IN (?) AND images.project_id IN (?)', image_ids, project_ids) : Image.where('images.id IN (?)', image_ids)
      if @images.length < 1
        redirect_back(fallback_url: my_projects_path, alert: 'No images selected or you may lack permission to edit these images')
      end
    end     
  end


end
