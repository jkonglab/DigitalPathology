class TilingWorker
  include Sidekiq::Worker
  require 'csv'
  attr_accessor :run, :image, :annotation, :algorithm
  sidekiq_options :retry => 3
  # This is imageviewer


  def perform(run_id, user_id)
    @run = Run.find(run_id)
    @run_time = Time.now.to_i
    @image = run.image
    @algorithm = run.algorithm
    puts @algorithm.name
    num_tiles_counter = 0
    tile_size = @run.tile_size || 256

    if @image && @image.complete
        @run.update_attributes!(:run_at=>@run_time, :processing=>true, :tiles_processed=>0)
        
        %x{
            mkdir #{@run.run_folder}
            chmod -R ug+rwx #{@run.run_folder};
        }
        puts @algorithm.output_type
        if @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"] or @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["landmarks"]
            puts "here1"
            # Queuing tile_x, tile_y = (0,0) means that there is no tiling required in this algorithm
            # set tilesize to 0
            @run.update_attributes(:tile_size=>0)
            @run.update_attributes!(:total_tiles=>1)
            Sidekiq::Client.push('queue' => 'user_analysis_queue_' + @run.users.first.id.to_s, 'class' =>  AnalysisWorker, 'args' => [run_id, user_id, 0, 0])
        elsif @algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["image"]
          puts "here2"
            if run.annotation_id != 0
              @annotation = run.annotation
              tile_x = @annotation.x_point
              tile_y = @annotation.y_point
              @run.update_attributes!(:total_tiles=>1)
              Sidekiq::Client.push('queue' => 'user_analysis_queue_' + @run.users.first.id.to_s, 'class' =>  AnalysisWorker, 'args' => [run_id, user_id, tile_x, tile_y])
            end
        # elsif @algorithm.name == "hyperion_segmentation" 
        #     puts "its hare"
        #     puts "running algorithm =>"
        #     puts @algorithm.name
        #     @run.update_attributes(:tile_size=>0)
        #     @run.update_attributes!(:total_tiles=>1)
        #     Sidekiq::Client.push('queue' => 'user_analysis_queue_' + @run.users.first.id.to_s, 'class' =>  AnalysisWorker, 'args' => [run_id, user_id, 0, 0])
        else
          puts "here, it should be here"
            if run.annotation_id != 0
              @annotation = run.annotation
              x, y = convert_and_save_annotation_points
            else
              x, y = convert_and_save_whole_slide_annotation
            end
            puts @image.file.path
            puts @run.run_folder
            puts tile_size
          #  %x{ 
          #       cd #{algorithm_path}; 
          #       matlab -nodisplay -r \"tiling('#{@image.file.path}','#{@run.run_folder}', #{tile_size}); exit;"
          #   }

            timer = 0
            until File.exist?(File.join(@run.run_folder,'/tiles_to_analyze.json'))
                timer +=1
                sleep 1
                if timer > 300
                    break
                end
            end

            tiles_file = File.read(File.join(@run.run_folder, '/tiles_to_analyze.json'))
            tiles = JSON.parse(tiles_file)
            tiles.each do |tile|
                tile_x = tile.split(',')[0].to_i
                tile_y = tile.split(',')[1].to_i
                if tile_x != @image.width and tile_y != @image.height
                    num_tiles_counter += 1
                end
            end
            @run.update_attributes!(:total_tiles=>num_tiles_counter)
            # puts tiles_file
            puts "file was succesfully created"

            tiles.each do |tile|
                tile_x = tile.split(',')[0].to_i
                tile_y = tile.split(',')[1].to_i
                if tile_x != @image.width and tile_y != @image.height 
                    if @algorithm.single_queue_flag
                        Sidekiq::Client.push('queue' => 'single_analysis_queue', 'class' =>  AnalysisWorker, 'args' => [run_id, user_id, tile_x, tile_y])
                    ##to accomodate invoking singulairty image for GPU algorithms 
                    elsif @algorithm.title[0..2] == "GPU"
                        Sidekiq::Client.push('queue' => 'single_analysis_queue', 'class' =>  AnalysisWorker, 'args' => [run_id, user_id, tile_x, tile_y])
                    else
                        Sidekiq::Client.push('queue' => 'user_analysis_queue_' + @run.users.first.id.to_s, 'class' =>  AnalysisWorker, 'args' => [run_id, user_id, tile_x, tile_y])
                    end
                end
            end
        end
        @run.check_if_done
    end
  end
  def algorithm_path
    return File.join(Rails.root.to_s, 'algorithms', 'matlab')
  end

  def convert_and_save_annotation_points
    x_coordinates = []
    y_coordinates = []
    if @annotation.data[0][0] == "path"
        annotation_points = @annotation.data[0][1]["d"].split("M")[1].split("Z")[0].split(" L")
        annotation_points.each do |point|
          point_array = point.split(' ')
          x_coordinates << point_array[0]
          y_coordinates << point_array[1]
        end
    else #rectangle annotation
        x_point = @annotation.data[0][1]["x"].to_f
        y_point = @annotation.data[0][1]["y"].to_f
        width = @annotation.data[0][1]["width"].to_f
        height = @annotation.data[0][1]["height"].to_f
        total_x = x_point + width
        x_coordinates = [x_point, x_point, x_point+width, x_point+width]
        y_coordinates = [y_point, y_point+height, y_point+height, y_point]
        # puts "x_coordinates =>"
        # puts x_coordinates
        # puts "y_coordinates =>"
        # puts y_coordinates
        # puts "total_x"
        # puts total_x
    end

    CSV.open(File.join(@run.run_folder, "/x_coordinates.csv"), "w") do |csv|
      csv << x_coordinates
    end

    CSV.open(File.join(@run.run_folder, "/y_coordinates.csv"), "w") do |csv|
      csv << y_coordinates
    end

    return x_coordinates, y_coordinates
  end

  def convert_and_save_whole_slide_annotation
    x = [0, 0, 100, 100]
    y = [0, 100, 100, 0]
    CSV.open(File.join(@run.run_folder, "/x_coordinates.csv"), "w") do |csv|
      csv << x
    end
    CSV.open(File.join(@run.run_folder, "/y_coordinates.csv"), "w") do |csv|
      csv << y
    end

    return x, y
  end

end
