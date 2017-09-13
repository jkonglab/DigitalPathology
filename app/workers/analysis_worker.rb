class AnalysisWorker
  include Sidekiq::Worker

  def perform(run_id, tile_x, tile_y, tile_size)
  	@run = Run.find(run_id)
  	@algorithm = @run.algorithm
    @image = @run.image
    @tile_x = tile_x
    @tile_y = tile_y
    @tile_size = tile_size

    algorithm_language = Algorithm::LANGUAGE_LOOKUP_INVERSE[@algorithm.language]
  	algorithm_path = Rails.root.to_s + '/algorithms/'+algorithm_language
  	image_path = Rails.root.to_s + '/public/' + Rails.application.config.data_directory + '/' + @image.upload_file_name
    run_folder = Rails.root.to_s + '/algorithms/run_data/' + 'run_' + @run.id.to_s + '_' + @run.run_at.to_s
    output_file_name = '/output_' + tile_x.to_s + '_' + tile_y.to_s + '.json'

    if @algorithm.language == Algorithm::LANGUAGE_LOOKUP["matlab"]
      %x{cd #{algorithm_path};
  		  matlab -nodisplay -r "main('#{image_path}','#{run_folder}',#{@run.parameters},'#{@algorithm.name}',#{tile_x},#{tile_y},#{tile_size}); exit;"
      }
    end

    timer = 0
    until File.exist?(run_folder + output_file_name)
      timer +=1
      sleep 1
      if timer > 300
          break
      end
    end

    output_file = File.read(run_folder + output_file_name)
    outputs = JSON.parse(output_file)
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

    @run.reload.increment!(:tiles_processed)
    if @run.reload.tiles_processed == @run.total_tiles
      @run.update_attributes!(:complete => true)
    end
  end

  def convert_to_svg_contour(contour)
    svg_data_string = ""

    contour.each do |point|
      point_x = point[0].to_i
      point_y = point[1].to_i
      vector_width = (((@tile_x.to_i + point_x).to_f / @image.width) * 100).round(2)
      vector_height = (((@tile_y.to_i + point_y).to_f / @image.height) * 100).round(2)

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
      "stroke"=> "blue",
      "stroke-width"=> 1,
      "stroke-linejoin"=> "round",
      "stroke-linecap"=> "round",
      "vector-effect"=> "non-scaling-stroke"
    }]

    return svg_data
  end

  def convert_to_svg_points(point)
    #NOT YET IMPLEMENTED
    return points
  end

end