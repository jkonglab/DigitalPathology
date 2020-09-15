class AnalysisWorker
  include Sidekiq::Worker
  attr_accessor :run, :tile_x, :tile_y
  sidekiq_options :retry => 3

  def perform(run_id, userid, tile_x, tile_y)
    @run = Run.find(run_id)
    @algorithm = @run.algorithm
    @annotation = @run.annotation
    @image = @run.image
    @tile_x = tile_x.to_i
    @tile_y = tile_y.to_i
    @tile_width = @run.tile_size
    @tile_height = @run.tile_size

    if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["image"]
        @tile_width = @annotation.width > 4096 ? 4096 : @annotation.width
        @tile_height = @annotation.height > 4096 ? 4096 : @annotation.height
        roi_type = "wholeslide"
        @work_folder = @run.run_folder
        output_file = @work_folder
        input_folder_path = @image.file_folder_path
    elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"] or @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["landmarks"]
        input_folder_path = @image.file_folder_path
        roi_type = "wholeslide"
        @work_folder = @run.run_folder
        output_file = File.join(@run.run_folder, "/output.json")
    else
        input_folder_path = @image.tile_folder_path
        output_file = File.join(@run.run_folder, "/output_#{tile_x.to_s}_#{tile_y.to_s}.json")
        roi_type = "dzi"
        @work_folder = "#{@run.run_folder}/#{tile_x.to_s}_#{tile_y.to_s}"
        %x{
          mkdir #{@work_folder};
          chmod -R ug+rwx #{@work_folder};
          chgrp webapp #{@work_folder}
        }
    end

    if !Rails.application.config.local_processing
      
      File.open("#{@work_folder}/job.sh", 'w') do |file|
            file.puts "#!/bin/bash"
            file.puts "#SBATCH -N 1"
            file.puts "#SBATCH -c 1"
            file.puts "#SBATCH -p qDPGPU"
            if @algorithm.title.include? "GPU"
                file.puts "#SBATCH --gres gpu:1"
            end
            file.puts "#SBATCH -t 1440"
            file.puts "#SBATCH -J a#{run_id}_#{userid}"
            file.puts "#SBATCH -e error%A.err"
            file.puts "#SBATCH -o out%A.out"
            file.puts "#SBATCH -A RS10272"
            file.puts "#SBATCH --oversubscribe"
            #file.puts "#SBATCH --uid #{user_name}"
            file.puts "#SBATCH --mem 4000"
            file.puts "sleep 7s"
            file.puts "export OMP_NUM_THREADS=4"
            file.puts "NODE=$(hostname)"
            file.puts "export MODULEPATH=/apps/Compilers/modules-3.2.10/Debug-Build/Modules/3.2.10/modulefiles/"
            file.puts "module load Image_Analysis/Openslide3.4.1"


        if @algorithm.language == Algorithm::LANGUAGE_LOOKUP["matlab"]
          parameters = fix_params_for_matlab(convert_parameters_cell_array_string(@run.parameters))
          file.puts "module load Framework/Matlab2019a"
          file.puts "module load Compilers/gcc-6.3.0"
          file.puts "mex -setup C++"
          file.puts "cd #{algorithm_path}"
          file.puts "matlab -nodisplay -r \"main('#{input_folder_path}','#{output_file}',#{parameters},'#{@algorithm.name}',#{@tile_x},#{@tile_y},#{@tile_width},#{@tile_height}); exit;\""
        
        elsif @algorithm.language == Algorithm::LANGUAGE_LOOKUP["python3"] ||  @algorithm.language == Algorithm::LANGUAGE_LOOKUP["python"] 
          parameters =  ""

          @run.parameters.each do |parameter|
            parameters = parameters + parameter.to_json + ' '
          end
          file.puts "cd #{algorithm_path}"
          ## FILTHY HACK
          if @algorithm.name == 'steatosis_neural_net'
            file.puts "module load Compilers/Python3.6"
            file.puts "module load Compilers/Cudalib"
            file.puts "source env3.6/bin/activate"
            #file.puts "cp -r #{algorithm_path}/steatosis_neural_net/mrcnn env3.6/lib/python3.6/site-packages"
            file.puts "python -m main #{input_folder_path} '#{@image.title}' #{output_file} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height} #{roi_type} #{parameters}"
          else
            file.puts "module load Compilers/Python3.7.4"
            if @algorithm.title.include? "GPU"
                file.puts "module load Cuda7.0"
            end
            file.puts "source env3.7/bin/activate"
            file.puts "python -m main #{input_folder_path} '#{@image.title}' #{output_file} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height} #{roi_type} #{parameters}"

          end
        elsif @algorithm.language == Algorithm::LANGUAGE_LOOKUP["julia"]
          ## NEEDS MAJOR REFACTORING!
          ## PRETTY MUCH BUILT ONLY TO RUN COLOR DECONV
          parameters = ""
          output_file = File.join(@work_folder, "/output.tif")
          @run.parameters.each do |parameter|
            parameters = parameters + parameter.to_json + ' '
          end
          file.puts "module load Compilers/Julia1.3.0"
          file.puts "cd #{algorithm_path}"
          file.puts "julia julia-adapter.jl #{@image.file.path} #{output_file} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height} #{parameters}"
        end
      end

      %x{ chmod -R 775 #{@work_folder};
          cd #{@work_folder};
          sbatch job.sh
      }

    else
      if @algorithm.language == Algorithm::LANGUAGE_LOOKUP["matlab"]
        parameters = convert_parameters_cell_array_string(@run.parameters)

        %x{
          cd #{algorithm_path};
          matlab -nodisplay -r "main('#{@image.tile_folder_path}','#{output_file}',#{parameters},'#{@algorithm.name}',#{@tile_x},#{@tile_y},#{@tile_width},#{@tile_height}); exit;"
        }

      elsif @algorithm.language == Algorithm::LANGUAGE_LOOKUP["python3"] ||  @algorithm.language == Algorithm::LANGUAGE_LOOKUP["python"] 
        parameters = @run.parameters

        ## FILTHY HACK
        if @algorithm.name == 'steatosis_neural_net'
            %x{cd #{algorithm_path};
                source env3.6/bin/activate;
                ## cp -r #{algorithm_path}/steatosis_neural_net/mrcnn env_3.6/lib/python3.6/site-packages;
                python -m main #{input_folder_path} '#{@image.title}' #{output_file} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height} #{roi_type} #{parameters}
              }
        else
            %x{cd #{algorithm_path};
                source env3.7/bin/activate;
                python -m main #{input_folder_path} '#{@image.title}' #{output_file} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height} #{roi_type} #{parameters}
              }
        end
    
      elsif @algorithm.language == Algorithm::LANGUAGE_LOOKUP["julia"]
        ## NEEDS MAJOR REFACTORING!
        ## PRETTY MUCH BUILT ONLY TO RUN COLOR DECONV
        parameters = ""
        output_file = File.join(@work_folder, "/output.tif")

        @run.parameters.each do |parameter|
          parameters = parameters + parameter.to_json + ' '
        end
        
        %x{cd #{algorithm_path};
          julia julia-adapter.jl #{@image.file.path} #{output_file} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height} #{parameters}
        }

      end
    end

    timer = 0
    until File.exist?(output_file)
        timer +=1
        sleep 1
        if timer > 36000
            break
        end
    end

    if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"]
      handle_3d_volume_output_generation
    elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["image"]
      handle_image_output_generation
    elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["landmarks"]
      handle_landmarks_output_generation
    else
      sleep 10
      raw = File.read(output_file)

      if raw.present?
        raw_outputs = JSON.parse(raw)

        if !@algorithm.multioutput
          raw_outputs.each do |output|
            if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
              svg_data = convert_to_svg_contour(output)
            elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
              svg_data = convert_to_svg_points(output)
            else
              svg_data = ""
            end

            if svg_data.present?
              new_result = @run.results.new(
                :tile_x => @tile_x,
                :tile_y => @tile_y,
                :raw_data => output,
                :svg_data => svg_data,
                :run_at => @run.run_at)

              new_result.save
            end
          end
        else
          @algorithm.multioutput_options.each_with_index do |option, index|
            output = raw_outputs[index]
            output_type = option["output_type"]
            output_key = option["output_key"]

            if output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
              output.each do |value|
                svg_data = convert_to_svg_contour(value)
                if svg_data.present?
                  new_result = @run.results.create!(
                    :tile_x => @tile_x,
                    :tile_y => @tile_y,
                    :raw_data => value,
                    :svg_data => svg_data,
                    :run_at => @run.run_at,
                    :output_key => output_key,
                    :output_type => output_type)
                end
              end
            elsif output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
              output.each do |value|
                svg_data = convert_to_svg_points(value)
                new_result = @run.results.create!(
                  :tile_x => @tile_x,
                  :tile_y => @tile_y,
                  :raw_data => value,
                  :svg_data => svg_data,
                  :run_at => @run.run_at,
                  :output_key => output_key,
                  :output_type => output_type)
              end
            else
              new_result = @run.results.create!(
              :tile_x => @tile_x,
              :tile_y => @tile_y,
              :raw_data => output,
              :run_at => @run.run_at,
              :output_key => output_key,
              :output_type => output_type)
            end
          end          
        end
      end
    end

    begin
      @run.reload.increment!(:tiles_processed)
    rescue ActiveRecord::StaleObjectError
      @run.reload.increment!(:tiles_processed)
    retry
    end

    begin
      @run.reload.check_if_done
    rescue ActiveRecord::StaleObjectError
      @run.reload.check_if_done
    retry
    end

  end

  def algorithm_path
    return File.join(Rails.root.to_s, 'algorithms', Algorithm::LANGUAGE_LOOKUP_INVERSE[@algorithm.language])
  end

  def handle_landmarks_output_generation
    output = []
    target_slice = 0
    result_hash = {}
    target_points = []
    ref_points = []
    Dir.entries(@work_folder + '/').each do |file_name|
      if file_name.include?('openSlide_global_surf_Landmark_L')
        File.open(@work_folder + '/'+file_name,'r').each_line do |line|
            data = line.strip.split(",")
            if data[0] != target_slice
                if target_points.length != 0 && ref_points.length != 0
                    result_hash["target_landmarks"] = target_points
                    result_hash["ref_landmarks"] = ref_points
                    output << result_hash
                    #save to landmarks
                    new_landmark = Landmark.create!(
                      :parent_id => @image.id,
                      :image_id => Image.where(:parent_id => @image.id, :slice_order => target_slice).first.id,
                      :image_data => target_points,
                      :ref_image_id => Image.where(:parent_id => @image.id, :slice_order => target_slice.next).first.id,
                      :ref_image_data => ref_points)
                    new_landmark.save!
                end
                target_slice = data[0]
                result_hash = {}
                target_points = []
                ref_points = []
                result_hash["target_id"] = data[0].to_i
                result_hash["reference_id"] = data[3].to_i
                target_points << [data[1],data[2]]
                ref_points << [data[4],data[5]]
            else
                target_points << [data[1],data[2]]
                ref_points << [data[4],data[5]]
            end
        end
        result_hash["target_landmarks"] = target_points
        result_hash["ref_landmarks"] = ref_points
        output << result_hash
        #save to landmarks
        new_landmark = Landmark.create!(
            :parent_id => @image.id,
            :image_id => Image.where(:parent_id => @image.id, :slice_order => target_slice).first.id,
            :image_data => target_points,
            :ref_image_id => Image.where(:parent_id => @image.id, :slice_order => target_slice.next).first.id,
            :ref_image_data => ref_points)
        new_landmark.save!
        new_result = @run.results.create!(
          :run_at => @run.run_at,
          :raw_data => output,
          :output_type => Algorithm::OUTPUT_TYPE_LOOKUP["landmarks"],
          :output_file => @work_folder + '/' +file_name)
        new_result.save!
      end
    end
  end

  def handle_image_output_generation  
        timer = 0
        until File.exist?(@run.run_folder+'/output.json')
            timer +=1
            sleep 1
            if timer > 36000
              break
            end
        end
        Dir.entries(@run.run_folder + '/').each do |file_name|
            if (file_name.include?('output') || file_name.include?('reg')) && file_name.include?('.tif')
                new_result = @run.results.create!(
                        :run_at => @run.run_at,
                        :tile_x => @tile_x,
                        :tile_y => @tile_y,
                        :output_file => file_name)
                new_result.save!
            end
        end
  end

  def handle_3d_volume_output_generation
    if @algorithm.name == 'get_level_image' #save level to results
      level = File.read(File.join(@run.run_folder, "/output.json")).strip
      new_result = @run.results.create!(
        :raw_data => level,
        :run_at => @run.run_at)
      new_result.save!
    end
    Dir.entries(@work_folder + '/').each do |file_name|
      if file_name.include?('.tif')
        i = 0
        while(true)
          begin
            layer = Vips::Image.tiffload File.join(@work_folder, file_name), :page => i
            layer.write_to_file(File.join(@work_folder, i.to_s + '_' + file_name))
            new_image = Image.new
            file = File.open(File.join(@work_folder, i.to_s + '_' + file_name))
            new_image.file = file
            file.close
            new_image.save!
            new_image.title = "Run #{@run.id}: #{new_image.file_file_name.gsub('_', ' ')}"
            new_image.image_type = Image::IMAGE_TYPE_TWOD
            new_image.generated_by_run_id = @run.id
            new_image.project_id = @run.image.project_id
            new_image.save!
            Sidekiq::Client.push('queue' => 'user_conversion_queue_' + @run.users.first.id.to_s, 'class' =>  ConversionWorker, 'args' => [new_image.id, @run.users.first.id.to_s])
            i = i + 1
          rescue Vips::Error
            break
          end
        end
      end
    end
  end

  def convert_parameters_cell_array_string(parameters)
    new_parameters = []
    parameters.each do |p|
        if p.kind_of?(Array)
            p = convert_parameters_cell_array_string(p)
        end
        new_parameters << p
    end
    converted_parameters = new_parameters.to_json.gsub('"', "'")
    converted_parameters[0] = '{'
    converted_parameters[-1] = '}'
    return converted_parameters
  end

  def fix_params_for_matlab(parameters)
    converted_parameters = parameters.to_s.gsub('\'{', "{")
    converted_parameters = converted_parameters.to_s.gsub('}\'', "}")
    return converted_parameters
  end

  def convert_to_svg_contour(contour)
    svg_data_string = ""

    contour.each do |point|
      point_x = point[0].to_i
      point_y = point[1].to_i
      vector_width = (((@tile_x.to_i + point_x).to_f / @image.width) * 100)
      vector_height = (((@tile_y.to_i + point_y).to_f / @image.height) * 100)

      if vector_height > 100 || vector_width > 100
        return nil
      end

      if svg_data_string.length == 0
        svg_data_string += "M" + vector_width.to_s + ' ' + vector_height.to_s
      else
        svg_data_string += ' L' + vector_width.to_s + ' ' + vector_height.to_s
      end
    end

    svg_data_string += "Z"

    svg_data = ["path", {
      "fill"=> "lime",      
      "d"=> svg_data_string,
      "stroke"=> "lime",
      "stroke-width"=> 2,
      "stroke-linejoin"=> "round",
      "stroke-linecap"=> "round",
      "vector-effect"=> "non-scaling-stroke"
    }]

    return svg_data
  end
  
  def convert_to_svg_points(point)
    point_x = point[0].to_i
    point_y = point[1].to_i
    vector_width = (((@tile_x.to_i + point_x).to_f / @image.width) * 100)
    vector_height = (((@tile_y.to_i + point_y).to_f / @image.height) * 100)
    
    svg_data = ["circle", {
      "cx"=>vector_width,
      "cy"=>vector_height,
      "r"=>"1px",
      "fill"=> "none",
      "stroke"=> "lime",
      "stroke-width"=> 3,
      "stroke-linejoin"=> "round",
      "stroke-linecap"=> "round",
      "vector-effect"=> "non-scaling-stroke"
    }]

    return svg_data
  end

end

