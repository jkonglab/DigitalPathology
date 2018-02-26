class AnalysisWorker
  include Sidekiq::Worker
  attr_accessor :run, :tile_x, :tile_y

  def perform(run_id, tile_x, tile_y)
    @run = Run.find(run_id)
    @algorithm = @run.algorithm
    @image = @run.image
    @tile_x = tile_x.to_i
    @tile_y = tile_y.to_i
    @tile_width = @run.tile_size
    @tile_height = @run.tile_size
    output_file = File.join(@run.run_folder, "/output_#{tile_x.to_s}_#{tile_y.to_s}.json")

    if @algorithm.language == Algorithm::LANGUAGE_LOOKUP["matlab"]
      parameters = convert_parameters_cell_array_string(@run.parameters)
      %x{cd #{algorithm_path}; matlab -nodisplay -r "main('#{@image.tile_folder_path}','#{output_file}',#{parameters},'#{@algorithm.name}',#{@tile_x},#{@tile_y},#{@tile_width},#{@tile_height}); exit;"}
    elsif @algorithm.language == Algorithm::LANGUAGE_LOOKUP["python"]
      parameters = @run.parameters
      %x{cd #{algorithm_path}; source env/bin/activate; python -m main #{@image.tile_folder_path} #{output_file} #{parameters} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height}}
    end

    timer = 0
    until File.exist?(output_file)
      timer +=1
      sleep 1
      if timer > 300
          break
      end
    end

    if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"]
      handle_3d_volume_output_generation
    else
      outputs = JSON.parse(File.read(output_file))
      outputs.each do |output|
        if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
          svg_data = convert_to_svg_contour(output)
        elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
          svg_data = convert_to_svg_points(output)
        else
          svg_data = ""
        end

        new_result = @run.results.new(:tile_x => @tile_x,
          :tile_y => @tile_y,
          :raw_data => output,
          :svg_data => svg_data,
          :run_at => @run.run_at)

        new_result.save
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

  def handle_3d_volume_output_generation
    Dir.entries(@run.run_folder + '/').each do |file_name|
      if file_name.include?('.tif')
        image_suffix =  file_name.split('.')[-1]
        image_title = file_name.split('.' + image_suffix)[0]
        
        new_image = Image.create!(
          :title => "Run #{@run.id.to_s}: #{image_title}", 
          :image_type => Image::IMAGE_TYPE_TWOD,
          :generated_by_run_id => @run.id)

        UserImageOwnership.create!(
          :user_id=> @run.user_id, :image_id=> new_image.id)

        new_file_name = "#{new_image.id}_#{file_name}"
        new_image.update_attributes(:upload_file_name => new_file_name)
        %x{cd #{@run.run_folder};
          mv #{file_name} #{new_file_name}
        }
        ConversionWorker.perform_async(new_image.id, @run.run_folder)
      end
    end
  end

  def convert_parameters_cell_array_string(parameters)
    converted_parameters = parameters.to_json.gsub('"', "'")
    converted_parameters[0] = '{'
    converted_parameters[-1] = '}'
    return converted_parameters
  end

  def convert_to_svg_contour(contour)
    svg_data_string = ""

    contour.each do |point|
      point_x = point[0].to_i
      point_y = point[1].to_i
      vector_width = (((@tile_x.to_i + point_x).to_f / @image.width) * 100)
      vector_height = (((@tile_y.to_i + point_y).to_f / @image.height) * 100)

      if svg_data_string.length == 0
        svg_data_string += "M" + vector_width.to_s + ' ' + vector_height.to_s
      else
        svg_data_string += ' L' + vector_width.to_s + ' ' + vector_height.to_s
      end
    end

    svg_data_string += "Z"

    svg_data = ["path", {
      "fill"=> "none",
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
      "r"=>0.05,
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