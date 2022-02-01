class RunsController < ApplicationController
  respond_to :html, :json
  before_action :authenticate_user!, :only => [:create, :index, :show, :get_results]
  before_action :set_runs_validated, :only =>[:confirm_delete, :delete]
  before_action :set_run_validated, :only => [:show, :get_results, :download_results]

  def index
    @runs = current_user.runs.order('id desc')
  end

  def show
    puts "Show function was triggered"
    @run = Run.find(params[:id])
    @algorithm = @run.algorithm
    @image = @run.image
    if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["landmarks"]
      @slice_dzi = []
      @slice_temp = []
      
      @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
      @slices.each do |slice|
        slice_hash = {}
        puts "Images path =>"
        puts slice.dzi_url
        slice_hash["dzi_url"] = slice.dzi_url
        slice_hash["id"] = slice.id
        slice_hash["height"] = slice.height
        slice_hash["width"] = slice.width
        @slice_temp << slice_hash
        @slice_dzi << slice.dzi_url
      end
      puts "landmark sliced image details =>"
      puts @slice_temp
      #default ref and target images
      @target_image = @slices[0]
      @ref_image = @slices[1]
    else
      @slices = Image.where('generated_by_run_id IN (?) AND (image_type = ? OR parent_id IS NOT NULL)', @run.id, Image::IMAGE_TYPE_TWOD).order('id desc')
    end

    @threed_volume = Image.where('generated_by_run_id IN (?) AND image_type = ? AND parent_id IS NULL', @run.id, Image::IMAGE_TYPE_THREED).first
    @annotation = @run.annotation
    puts "annotation id=>"
    puts @annotation.id

    @results = @algorithm.multioutput ? @run.results.where(:output_key=>@algorithm.multioutput_options[0]["output_key"]).order('id asc') : @run.results.order('id asc')

    puts "test_result=>"
    @test_result = @run.results.where('exclude IS NOT true').order('output_key asc, id asc')
    @test_result.each do |result|
      puts "here =>"
      puts result.raw_data
      break;
    end
    
    if @results.count < 10000
        @results_data = @results.pluck(:svg_data, :id, :exclude)
    else
      @results = [0]
      @results_data = [0]
    end
   
    if @algorithm.multioutput
      @numerical_result_hash = {}
      @algorithm.multioutput_options.each do |option|
        key = option["output_key"]
        if option["output_type"] == Algorithm::OUTPUT_TYPE_LOOKUP["scalar"]
          @numerical_result_hash[key.to_sym] = @run.results.where(:output_key=>key).pluck(:raw_data).sum
        elsif option["output_type"] == Algorithm::OUTPUT_TYPE_LOOKUP["percentage"]
          if (@algorithm.name != "steatosis")
            results = @run.results.where(:output_key=>key).pluck(:raw_data)
            @numerical_result_hash[key.to_sym] = results.length > 0 ? (results.sum / results.length) : 0
          end
        end
      end
    end
  end

  def get_results
    puts "get_result function was triggered"
    @run = Run.find(params[:id])
    @algorithm = @run.algorithm
    @output_file = @run.run_folder + "/pr_result.json"	
    @pr_analysis_done = true
    @percentage = 0
    puts "Algorithm Name =>"
    puts @algorithm.name
    puts @algorithm.multioutput
    if @algorithm.multioutput
        puts "here"
    end
    puts @run.complete
    if @run.complete
      if @algorithm.name == "steatosis"|| @algorithm.name == "fibrosis" || @algorithm.name == "steatosis_neural_net"
        puts "Getting result for steatosis"
        
        puts current_user
        puts @run.percentage
        if @run.percentage_analysis_done == false || @run.percentage_analysis_done == nil
          puts "here"
          puts @run.percentage
          if File.exist?(@output_file)
            output_json = File.read(@output_file)
            output_hash = JSON.parse(output_json)
            @pr_analysis_done = output_hash['pr_analysis_done']
            @percentage = output_hash['percentage']
            puts "output hash =>"
            puts output_hash 
            puts "percentage =>"
            puts @percentage
            # type(@percentage)
            puts "done =>"
            puts @pr_analysis_done
            @run.percentage = @percentage
            if @pr_analysis_done == true
              @run.percentage_analysis_done = true
            else 
              @run.percentage_analysis_done = false
            end
          @run.save
          else 
            Sidekiq::Client.push('queue' => 'pr_result_queue_' + current_user.id.to_s, 'class' =>  PRWorker, 'args' => [@run.id, current_user.id])
      # TODO
          end
        end
      end
    end

    @results = @run.results.where('tile_x >= ? AND tile_x <= ? AND tile_y >= ? AND tile_y <= ?', params['x'].to_f - @run.tile_size, (params['x'].to_f + params["width"].to_f), params['y'].to_f - @run.tile_size, (params['y'].to_f + params["height"].to_f))

    if params["key"]
      @results = @results.where(:output_key=>params["key"]).order('id asc')
    elsif @algorithm.multioutput 
      @results = @results.where(:output_key=>@algorithm.multioutput_options[0]["output_key"]).order('id asc')
    end

    if @results.count < 10000
      @results_data = @results.pluck(:svg_data, :id, :exclude)
    else
      @results = [0]
      @results_data = [0]
    end
    respond_with @results_data.to_json
  end

  def create
    @run = Run.new(run_params)
    image = Image.find(@run.image_id)
    algorithm = Algorithm.find(@run.algorithm_id)
    temp_idx = current_user.email.index('@')
    user_name = current_user.email[0..temp_idx-1]

    if algorithm.tile_size
        @run.tile_size = algorithm.tile_size
    end

    if @run.annotation_id.blank?
        @run.annotation_id = 0  # Denotes this as a whole slide annotation
        annotation = image.annotations.new(:label=> 'Whole Slide') # Make a dummy blank annotation
    else
        annotation = Annotation.find(@run.annotation_id)
    end

    run_parameters = []
    puts "checking algorithm parameters =>"
    puts algorithm.parameters

    algorithm_parameters = algorithm.parameters.sort_by { |k| k["order"] }

    puts "algorithm parameter loop section =>"
    puts algorithm_parameters
    puts "algorithm name =>"
    puts algorithm.name
    # puts algorithm_parameter["images_array"]

    algorithm_parameters.each do |algorithm_parameter|
      puts "algorithm parameter =>"
      puts algorithm_parameter
        if algorithm_parameter["hard_coded"]
            parameter_value = algorithm_parameter["default_value"]
        elsif algorithm_parameter["annotation_derived"]
            parameter_value = annotation[algorithm_parameter["annotation_key"]]
        elsif algorithm_parameter["images_array"]
            input_images_array = []
            puts "algorithm_name"
            puts algorithm.name
            if algorithm.name == "high_low_registration" or algorithm.name == "get_level_image" or algorithm.name == "global_machine_L" or algorithm.name == "registration_post_processingV2"
                Image.where(:parent_id => image.id).order('slice_order asc').each do |i|
                    input_images_array << File.join(i.file_folder_path, i.file_file_name)
                    puts "input_images_array"
                    puts input_images_array
                end
                parameter_value = input_images_array
            elsif algorithm.name == "generate_registered_images"
                    Image.where(:parent_id => image.id).order('slice_order asc').each do |i|
                        input_images_array << File.join(i.file_folder_path, i.file_file_name)
                    end
                    #write to file
                    puts "image id used to generate landmark"
                    puts image.id
                    corrected_landmarks = Landmark.where(:parent_id => image.id)
                    puts "corrected_landmarks =>"
                    puts corrected_landmarks
                    file_path = image.file_folder_path
                    if !File.directory?(file_path)
                        FileUtils.mkdir_p file_path
                    end
                    
                    File.open(file_path+'/openSlide_global_surf_Landmark_Corrected_L.json', 'w+') { |f|
                        corrected_landmarks.each_with_index do |image_pair, index|
                          image_pair.image_data.zip(image_pair.ref_image_data).each do |trgt, ref|
                            f.puts index.next.to_s+","+trgt.join(",")+","+ref.join(",")+"\n"
                          end
                        end
                    }
                    parameter_value = [input_images_array, file_path+'/openSlide_global_surf_Landmark_Corrected_L.json']
            end
        else
            puts "here I am ruuning params =>"
            puts params
            puts "checking params =>"
            # puts params["parameters"].empty?
            # puts params["parameters"]
            if (!params["parameters"].nil?)
            parameter_value = params["parameters"][algorithm_parameter["key"]]
            if algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["integer"]
                if algorithm.name == "high_low_registration"
                    r = Run.find(parameter_value.to_i)
                    Dir.entries(r.run_folder + '/').each do |file_name|
                        if file_name.include?('mat')
                            parameter_value =  r.run_folder + '/' + file_name
                        end
                    end
                else
                    parameter_value = parameter_value.to_i
                end
            elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["float"]
                parameter_value = parameter_value.to_f
            elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["boolean"]
                parameter_value = parameter_value == "1"
            elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["array"]
                if !parameter_value.blank?
                    begin
                        parameter_value = JSON.parse(parameter_value)
                    rescue JSON::ParserError
                        redirect_to image, alert: 'Could not parse your input array in analysis parameters.  Please make sure your arrays are comma separated and contained within square brackets [like, this]'
                        return
                    end
                end
            elsif algorithm_parameter["type"] == Algorithm::PARAMETER_TYPE_LOOKUP["file"]
                if !parameter_value.blank?
                    file_path = Rails.root.join('public','uploads',parameter_value.original_filename)
                    File.open(file_path,'wb') do |file|
                        file.write(parameter_value.read)
                        File.chmod(0777, file_path)
                    end
                    parameter_value = parameter_value.original_filename.to_s
                end
            end
          end
        end
          if (parameter_value.nil?)
            parameter_value = 'file_not_there'
          end
          run_parameters << parameter_value
    end
    @run.parameters = run_parameters
    

    if @run.save
        UserRunOwnership.create!(:user_id=> current_user.id,:run_id=> @run.id)
        puts "Run Analysis was triggered here!"
        puts "Not running workers for now!"
        Sidekiq::Client.push('queue' => 'user_tiling_queue_' + current_user.id.to_s, 'class' =>  TilingWorker, 'args' => [@run.id, current_user.id])
        redirect_to @run, notice: 'New analysis created, please wait for it to finish running.'
    end
  end

  def confirm_delete
    if @runs.length == 1
      run = @runs[0]
      run.destroy
      FileUtils.rm_rf(run.run_folder)
      return redirect_to runs_path, notice: "Analysis #{run.id} deleted"
    end
  end

  def delete
    length = @runs.length
    @runs.each do |run|
      run.destroy
      FileUtils.rm_rf(run.run_folder)
    end
    #@runs.destroy_all
    return redirect_to runs_path, notice: "#{length} analyses deleted"
  end

  def download_results
    puts "result download function triggered here"
    @run = Run.find(params[:id])
    @results = @run.results.where('exclude IS NOT true').order('output_key asc, id asc')
    @algorithm = @run.algorithm
    output = []
    if @algorithm.output_type != Algorithm::OUTPUT_TYPE_LOOKUP["image"]
      if @algorithm.name == 'generate_registered_images'
        files = Dir[@run.run_folder+"/*.mat"]
        puts "files are =>"
        puts files
        output_file = files.first
        puts "output files are =>"
        puts output_file
        puts File.basename(output_file)
        puts @run.run_folder
        if !File.exist?(@run.run_folder+'/results.zip')
          puts "here bitch";
            ::Zip::File.open(@run.run_folder+'/results.zip', Zip::File::CREATE) do |z|
              z.add(File.basename(output_file), output_file)
            end
        end
        send_file  @run.run_folder+'/results.zip' , :type => "application/zip", :disposition => "attachment"
      else
        @results.each do |result|
          result_hash = {}
          result_hash["output_key"] = result.output_key
          result_hash["tile_coordinate"] = [result.tile_x, result.tile_y]
          result_hash["local_coordinates"] = result.raw_data
          result_hash["tile_size"] = result.run.tile_size
          result_hash["raw_data"] = result.raw_data
          absolute_data = result.raw_data.deep_dup
          output_type = result.output_type || @algorithm.output_type

          if output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
            absolute_data.map{ |data_item|
              data_item[0] += result.tile_x
              data_item[1] += result.tile_y
            }
            result_hash["absolute_coordinates"] = absolute_data
          elsif output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
            absolute_data[0] += result.tile_x
            absolute_data[1] += result.tile_y
            result_hash["absolute_coordinates"] = absolute_data
          end

          output << result_hash
        end
        send_data output.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=results.json"
      end
    else
        if !File.exist?(@run.run_folder+'/results.zip')
          puts "here bitch2"
        ::Zip::File.open(@run.run_folder+'/results.zip', Zip::File::CREATE) do |z|
            @results.each do |result|
                z.add(result.output_file, File.join(@run.run_folder ,result.output_file))
            end
        end
        end
        send_file  @run.run_folder+'/results.zip' , :type => "application/zip", :disposition => "attachment"
    end
  end

  def annotation_form
    @image = Image.find(params[:image_id])
    @annotations = @image.hidden? ? @image.annotations.where(:user_id=>current_user.id).order('id desc') : @image.annotations
    @run = current_user.runs.new
    render partial: 'annotation_form'
  end

  def gpu_status
    @output_file = "/Users/ohm/imageviewer/public/data/gpu_status.json"
    gpu_json = File.read(@output_file)
    output_hash = JSON.parse(gpu_json)
    @gpu_status = output_hash["GPU_available"]
    render json: @gpu_status
  end

  private
    def run_params
        params.require(:run).permit(:image_id, :algorithm_id, :parameters, :annotation_id, :tile_size)
    end

    def set_run_validated
      @run = Run.find(params[:id])
      if !(@run.users.pluck(:id).include?(current_user.id))
        redirect_to runs_path, alert: 'You do not have permission to access or edit this analysis'
      end
    end

    def set_runs_validated
      run_ids = params['run_ids']
      if !run_ids
        redirect_to runs_path, alert: 'No analysis selected'
      else
        @runs = current_user.runs.where('runs.id IN (?)', run_ids)
        if @runs.length < 1
          redirect_to runs_path, alert: 'No analysis selected or you may lack permission to access these analyses'
        end
      end     
    end

    def create_annotation_file(annotation)
      output = []
      result_hash = {}
      result_hash["name"] = annotation.label
      result_hash["annotation_class"] = annotation.annotation_class
      puts result_hash["name"]
      annotation_data_arr = []
      annotation_data = {}
      if annotation.data[0][0] == "path"
        if annotation.data[0[1]]["d"].include?"L"
          annotation_data["annotation_object"] = "contour"
        end
      end
      
    end
end
