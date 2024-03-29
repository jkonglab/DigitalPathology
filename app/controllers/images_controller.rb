class ImagesController < ApplicationController
  include ApplicationHelper
  before_action :set_current_user
  before_action :authenticate_user!, :except => [:index, :show]
  before_action :set_image_validated, :only => [:show_3d, :show_volume, :download_annotations, :show, :add_single_clinical_data, :add_upload_clinical_data, :get_slice, :import_annotations]
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
    puts 'Run =>'
    puts @image.title
    @algorithm_name = get_algorithm_name(@image.title)
    puts @algorithm_name
    @algorithm = @image.threed? && @image.parent_id.blank? ? Algorithm.all : Algorithm.where('input_type NOT IN (?)', Algorithm::INPUT_TYPE_LOOKUP["3D"])
    @annotation = Annotation.new
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    
    if current_user.admin?
        @annotations = @image.annotations
    end
    @clinical_data = @image.clinical_data || {}
    @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
    if @slices.length.odd?
      default_slice = (@slices.length.to_f/2).floor(0)
    else
      default_slice = (@slices.length.to_f/2).floor(0)-1
    end 
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
    @slice = Image.where(:parent_id => @image.id).order('slice_order asc')[params[:slice].to_i - 1]
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
    puts "convert 3d images is triggered"
    puts "params"
    puts params['image_ids']
    @images = @images.order('title asc')
    if @images.length < 1
      return redirect_to @images.first.project, alert: 'Volume could not be created because all selected images are already attached to a 3D volume.'
    end
  end

  def convert_3d
    i = 1
    ref_image = nil
    refIdx = (params['image_ids'].length.to_f/2).floor(0)
    params['image_ids'].each do |id|
      image = Image.find(id.to_i)
      if refIdx == i
        ref_image = image
      end
      if image
        image.update_attributes!(:slice_order => i, :image_type => Image::IMAGE_TYPE_THREED)
        i += 1
      end
    end

    parent_image = Image.create!(
      :title => '3D Volume: ' + ref_image.title, 
      :image_type => Image::IMAGE_TYPE_THREED, 
      :visibility => ref_image.visibility,
      :processing => false,
      :complete => true,
      :file_file_name => ref_image.file_file_name,
      :file_content_type => ref_image.file_content_type,
      :file_file_size => ref_image.file_file_size,
      :file_updated_at => ref_image.file_updated_at,
      :clinical_data => ref_image.clinical_data,
      :generated_by_run_id => ref_image.generated_by_run_id,
      :project_id => ref_image.project_id,
      :height => ref_image.height,
      :width => ref_image.width
    )

    @images.update_all(:parent_id=> parent_image.id)
    @images.update_all(:visibility=> parent_image.visibility)
    puts "parent_image =>"
    puts parent_image.id
    Sidekiq::Client.push('queue' => 'convert3d_queue_' + current_user.id.to_s, 'class' => Convert3dWorker, 'args' => [parent_image.id, current_user.id])
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
        annotations = annotation_hash["annotations"] 
        annotations.each do |data|
            annotation_data = data["annotation_data"]
            annotation_data.each do |a|
                annotation = @image.annotations.new
                annotation.user_id = current_user.id
                if a["annotation_object"] == "contour"
                    points = a["absolute_coordinates"]
                    svg = convert_to_svg_contour(points, @image)
                elsif a["annotation_object"] == "rectangle"
                    points = a["rect_coordinates"]
                    width = a["width"]
                    height = a["height"]
                    svg = convert_to_svg_rect(points, width, height, @image)
                elsif a["annotation_object"] == "circle"
                    points = a["center_coordinates"]
                    radius = a["radius"]
                    svg = convert_to_svg_circle(points, radius, @image)
                elsif a["annotation_object"] == "point"
                    points = a["absolute_coordinates"]
                    svg = convert_to_svg_contour(points, @image)
                end
                bbox_coordinates = a["bbox_coordinates"]
                annotation.update_attributes({
                  :data=>[svg],
                  :label=>annotation_hash["name"],
                  :annotation_class=>data["annotation_class"],
                  :annotation_type=>a["annotation_type"],
                  :x_point=>bbox_coordinates[0],
                  :y_point=>bbox_coordinates[1],
                  :width=>a["bbox_width"],
                  :height=>a["bbox_height"]
                  })
                annotation.save!
            end
        end
      end
      redirect_to @image, notice: "#{json.length} annotations added successfully."
    rescue JSON::ParserError
      redirect_to @image, alert: 'Error parsing JSON file.  Please validate the file using a linter and make sure keys are double quoted!'
    end
  end

  def download_annotations
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    if current_user.admin?
        @annotations = @image.annotations
    end
    output = []
    labels = @annotations.group_by(&:label)
    labels.each_pair do |label, data|
      result_hash = {}
      result_hash["name"] = label
      result_classes_arr = []
      classes = data.group_by(&:annotation_class)
      classes.each_pair do |a_class, a_data|
        classes = {}
        classes["annotation_class"] = a_class
        annotation_data_arr = []
        a_data.each do |a|
            annotation_data = {}
            if a.data[0][0] == "path"
                points = []
                if a.data[0][1]["d"].include?"L"
                    annotation_data["annotation_object"] = "contour"
                    annotation_points = a.data[0][1]["d"].split("M")[1].split("Z")[0].split(" L")
                    annotation_points.each do |point|
                        point_array = point.split(' ')
                        points << [(((point_array[0].to_f)*@image.width)/100).to_i, (((point_array[1].to_f)*@image.height)/100).to_i]
                    end
                else
                    annotation_data["annotation_object"] = "point"
                    annotation_points = a.data[0][1]["d"].split("M")[1].split("Z")[0]
                    point_array = annotation_points.split(' ')
                    points << [(((point_array[0].to_f)*@image.width)/100).to_i, (((point_array[1].to_f)*@image.height)/100).to_i]
                end
                annotation_data["bbox_coordinates"] = [a.x_point, a.y_point]
                annotation_data["bbox_width"] = a.width
                annotation_data["bbox_height"] = a.height
                annotation_data["absolute_coordinates"] = points
            elsif a.data[0][0] == "rect"
                annotation_data["annotation_object"] = "rectangle"
                annotation_data["bbox_coordinates"] = [a.x_point, a.y_point]
                annotation_data["bbox_width"] = a.width
                annotation_data["bbox_height"] = a.height
                annotation_data["rect_coordinates"] = [(((a.data[0][1]["x"].to_f)*@image.width)/100).to_i , (((a.data[0][1]["y"].to_f)*@image.height)/100).to_i]
                annotation_data["width"] = (((a.data[0][1]["width"].to_f)*@image.width)/100).to_i 
                annotation_data["height"] = (((a.data[0][1]["height"].to_f)*@image.height)/100).to_i 
            elsif a.data[0][0] == "circle"
                annotation_data["annotation_object"] = "circle"
                annotation_data["bbox_coordinates"] = [a.x_point, a.y_point]
                annotation_data["bbox_width"] = a.width
                annotation_data["bbox_height"] = a.height
                annotation_data["center_coordinates"] = [(((a.data[0][1]["cx"].to_f)*@image.width)/100).to_i , (((a.data[0][1]["cy"].to_f)*@image.height)/100).to_i]
                annotation_data["radius"] = (((a.data[0][1]["r"].to_f)*@image.width)/100).to_i 
            end
            annotation_data["annotation_type"] = a.annotation_type
            annotation_data_arr << annotation_data
        end
        classes["annotation_data"] = annotation_data_arr
        result_classes_arr << classes
      end
      result_hash["annotations"] = result_classes_arr
      output << result_hash
    end
    send_data output.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=#{@image.title.split('.')[0]}_annotations.json"
  end

  def download_annotations_xml
    @image = Image.find(params[:id])
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    if current_user.admin?
        @annotations = @image.annotations
    end
    classes = @annotations.group_by(&:annotation_class)

    regAttrs = [{"Id":"9998", "Name":"Region" },
    {"Id":"9997", "Name":"Length" },
    {"Id":"9996", "Name":"Area" },
    {"Id":"9998", "Name":"Text" }]

    builder = Nokogiri::XML::Builder.new { |xml|
      xml.Annotations('MicronsPerPixel' => '') do
          classes.each_pair do |annotation_class, data|
            annotation_id = 0
            annotation_id = annotation_id+1
            xml.Annotation(:Id=>annotation_id, :Name=>annotation_class, :ReadOnly=>"0", :NameReadOnly=>"0", :LineColorReadOnly=>"0", :Incremental=>"0", :Type=>"9", :LineColor=>"65280", :Visible=>"1", :Selected=>"0", :MarkupImagePath=>"", :MacroName=>""){
            xml.Attributes{
              xml.Attribute(:Name=>"Annotation Class", :Id=>"1",:Value=>annotation_class)
            }
            xml.Regions{
              xml.RegionAttributeHeaders{
                regAttrs.each do |attr|
                    xml.AttributeHeader(:Id=>attr[:Id], :Name=>attr[:Name], :ColumnWidth=>"-1")
                end
              }
              data.each do |a|
              display_id = 0
              display_id = display_id+1
              if a["data"][0][0] == "circle"
                type = 2
              elsif a["data"][0][0] == "rect"
                type = 1
              elsif (a["data"][0][0] == "path") && (a["data"][0][1]["d"].include? "L")
                type = 0
              else
                type = 5
              end

              xml.Region(:Id=>a["id"], :Type=>type, :Zoom=>"" ,:Selected=>"0", :ImageLocation=>"", :ImageFocus=>"-1", :Length=>"0.0", :Area=>"0.0", :LengthMicrons=>"0.0", :AreaMicrons=>"0.0", :Text=>"", :NegativeROA=>"0" ,:InputRegionId=>"0", :Analyze=>"0", :DisplayId=>display_id){
              xml.Attributes{}
              xml.Vertices{
                if a["data"][0][0] == "rect"
                    xml.Vertex(:X=>a["x_point"], :Y=>a["y_point"],:Z=>"0")
                    xml.Vertex(:X=>a["x_point"], :Y=>a["y_point"]+a["height"],:Z=>"0")
                    xml.Vertex(:X=>a["x_point"]+a["width"], :Y=>a["y_point"]+a["height"],:Z=>"0")
                    xml.Vertex(:X=>a["x_point"]+a["width"], :Y=>a["y_point"],:Z=>"0")
                elsif a["data"][0][0] == "circle"
                    #xml.Vertex(:X=>(((a["data"][0][1]["cx"].to_f)*@image.width)/100).to_i-(((a.data[0][1]["r"].to_f)*@image.width)/100).to_i, :Y=>(((a["data"][0][1]["cy"].to_f)*@image.height)/100).to_i-(((a.data[0][1]["r"].to_f)*@image.width)/100).to_i,:Z=>"0")
                    xml.Vertex(:X=>a["x_point"], :Y=>a["y_point"],:Z=>"0")
                    #xml.Vertex(:X=>(((a["data"][0][1]["cx"].to_f)*@image.width)/100).to_i+(((a.data[0][1]["r"].to_f)*@image.width)/100).to_i, :Y=>(((a["data"][0][1]["cy"].to_f)*@image.height)/100).to_i+(((a.data[0][1]["r"].to_f)*@image.width)/100).to_i,:Z=>"0")
                    xml.Vertex(:X=>a["x_point"]+a["width"], :Y=>a["y_point"]+a["height"],:Z=>"0")
                elsif (a["data"][0][0] == "path")  && (a["data"][0][1]["d"].include? "L")
                    annotation_points = a["data"][0][1]["d"].split("M")[1].split("Z")[0].split(" L")
                        annotation_points.each do |point|
                            point_array = point.split(' ')
                            xml.Vertex(:X=>(((point_array[0].to_f)*@image.width)/100).to_i, :Y=>(((point_array[1].to_f)*@image.height)/100).to_i,:Z=>"0")
                        end
                else    
                    annotation_points = a.data[0][1]["d"].split("M")[1].split("Z")[0] 
                    point_array = annotation_points.split(' ')   
                    xml.Vertex(:X=>(((point_array[0].to_f)*@image.width)/100).to_i, :Y=>(((point_array[1].to_f)*@image.height)/100).to_i,:Z=>"0")  
                end
             }
            }
            end
           }
          }
          end
      end
    }
    send_data builder.to_xml, :type => 'application/xml; header=present', :disposition => "attachment; filename=#{@image.title.split('.')[0]}_annotations.xml"
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

  # def show_volume
  #   puts "here";
  #   @test = "hello!"
  # end
  def get_algorithm_name title
    s_title = title.split(" ")
    if s_title.include? "Run"
      run_id = s_title[3]
      run_id.slice! ':'
      puts run_id
      algorithm_id = Run.find(run_id).algorithm_id
      puts algorithm_id
      algorithm_name = Algorithm.find(algorithm_id).name
      puts algorithm_name
      return algorithm_name
    else 
      return nil
    end
  end
end
