class AnalysisWorker
  include Sidekiq::Worker
  attr_accessor :run, :tile_x, :tile_y
  sidekiq_options :retry => 3

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
      logger.info "main('#{@image.tile_folder_path}','#{output_file}',#{parameters},'#{@algorithm.name}',#{@tile_x},#{@tile_y},#{@tile_width},#{@tile_height}); exit;"
      %x{cd #{algorithm_path}; matlab -nodisplay -r "main('#{@image.tile_folder_path}','#{output_file}',#{parameters},'#{@algorithm.name}',#{@tile_x},#{@tile_y},#{@tile_width},#{@tile_height}); exit;"}
    elsif @algorithm.language == Algorithm::LANGUAGE_LOOKUP["python"]
      parameters = @run.parameters
      %x{cd #{algorithm_path}; source env/bin/activate; python3 -m main #{@image.tile_folder_path} #{output_file} #{parameters} #{@algorithm.name} #{@tile_x} #{@tile_y} #{@tile_width} #{@tile_height}}
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
      raw_outputs = JSON.parse(File.read(output_file))

      if !@algorithm.multioutput
        raw_outputs.each do |output|
          if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
            svg_data = convert_to_svg_contour(output)
          elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
            svg_data = convert_to_svg_points(output)
          else
            svg_data = ""
          end

          new_result = @run.results.new(
            :tile_x => @tile_x,
            :tile_y => @tile_y,
            :raw_data => output,
            :svg_data => svg_data,
            :run_at => @run.run_at)

          new_result.save
        end
      else
        @algorithm.multioutput_options.each_with_index do |option, index|
          output = raw_outputs[index]
          output_type = option["output_type"]
          output_key = option["output_key"]

          if output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
            output.each do |value|
              svg_data = convert_to_svg_contour(value)
              new_result = @run.results.create!(
                :tile_x => @tile_x,
                :tile_y => @tile_y,
                :raw_data => value,
                :svg_data => svg_data,
                :run_at => @run.run_at,
                :output_key => output_key,
                :output_type => output_type)
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
        new_image = Image.new
        file = File.open(File.join(@run.run_folder, file_name))
        new_image.file = file
        file.close
        new_image.save!
        new_image.title = "Run #{@run.id}: #{new_image.file_file_name.gsub('_', ' ')}"
        new_image.image_type = Image::IMAGE_TYPE_TWOD
        new_image.generated_by_run_id = @run.id
        new_image.save!
        UserImageOwnership.create!(:user_id=> @run.user_id,:image_id=> new_image.id)
        Sidekiq::Client.push('queue' => 'user_conversion_queue_' + @run.user_id.to_s, 'class' =>  ConversionWorker, 'args' => [new_image.id])
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