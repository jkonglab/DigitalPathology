class AnalysisWorker
  include Sidekiq::Worker

  def perform(run_id, tile_x, tile_y, tile_width, tile_height)
  	@run = Run.find(run_id)
  	@algorithm = @run.algorithm
    @image = @run.image
    @tile_x = tile_x.to_i
    @tile_y = tile_y.to_i
    @tile_width = tile_width.to_i
    @tile_height = tile_height.to_i

    algorithm_language = Algorithm::LANGUAGE_LOOKUP_INVERSE[@algorithm.language]
  	algorithm_path = Rails.root.to_s + "/algorithms/#{algorithm_language}"
  	image_path = Rails.root.to_s + '/public/' + Rails.application.config.data_directory + '/' + @image.upload_file_name
    run_folder = Rails.root.to_s + '/algorithms/run_data/' + 'run_' + @run.id.to_s + '_' + @run.run_at.to_s
    output_file_name = '/output_' + tile_x.to_s + '_' + tile_y.to_s + '.json'
    
    parameters = convert_parameters_cell_array_string(@run.parameters)

    if @algorithm.language == Algorithm::LANGUAGE_LOOKUP["matlab"]
      %x{cd #{algorithm_path}; matlab -nodisplay -r "main('#{image_path}','#{run_folder}',#{parameters},'#{@algorithm.name}',#{tile_x},#{tile_y},#{tile_width},#{tile_height}); exit;"}
    end

    timer = 0
    until File.exist?(run_folder + output_file_name)
      timer +=1
      sleep 1
      if timer > 300
          break
      end
    end

    if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"]
      handle_3d_volume_output_generation(run_folder)
    else
      outputs = JSON.parse(File.read(run_folder + output_file_name))
      outputs.each do |output|
        if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["contour"]
          svg_data = convert_to_svg_contour(output)
        elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["points"]
          svg_data = convert_to_svg_points(output)
        else
          svg_data = ""
        end

        new_result = @run.results.new(:tile_x => tile_x,
          :tile_y => tile_y,
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

    if @run.reload.tiles_processed >= @run.total_tiles
      @run.update_attributes!(:complete => true)
    end
  end

  def handle_3d_volume_output_generation(run_folder)
    Dir.entries(run_folder + '/').each do |file_name|
      if file_name.include?('.tif')
        image_suffix =  file_name.split('.')[-1]
        image_title = file_name.split('.' + image_suffix)[0]
        new_image = Image.create!(
          :title => "Run #{@run.id.to_s}: #{image_title}", 
          :user_id=>@run.user_id, 
          :image_type => Image::IMAGE_TYPE_TWOD,
          :generated_by_run_id => @run.id)

        new_file_name = "#{new_image.id}_#{file_name}"
        new_image.update_attributes(:upload_file_name => new_file_name)
        %x{cd #{run_folder};
          mv #{file_name} #{new_file_name}
        }
        ConversionWorker.perform_async(new_image.id, run_folder)
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
      "stroke"=> "green",
      "stroke-width"=> 1,
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
      "stroke"=> "green",
      "stroke-width"=> 1,
      "stroke-linejoin"=> "round",
      "stroke-linecap"=> "round",
      "vector-effect"=> "non-scaling-stroke"
    }]

    return svg_data
  end

end