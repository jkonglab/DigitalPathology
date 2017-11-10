class TilingWorker
  include Sidekiq::Worker
  require 'csv'

  TILING_FACTOR = 100

  def perform(run_id)
    run = Run.find(run_id)
    image = run.image
    annotation = run.annotation
    algorithm = run.algorithm
    run_time = Time.now.to_i
    x_coordinates = []
    y_coordinates = []
    num_tiles_counter = 0

    if image && !image.path.blank? && !image.processing && annotation && !run.processing
        algorithm_path = Rails.root.to_s + '/algorithms/matlab'
        run_data_path = Rails.root.to_s + '/algorithms/run_data/'
        data_file_path = Rails.root.to_s + '/public/' + Rails.application.config.data_directory + '/'
        image_path = data_file_path + image.upload_file_name
        run_folder = 'run_' + run.id.to_s + '_' + run_time.to_s
        run.update_attributes!(:run_at=>run_time, :processing=>true, :tiles_processed=>0)

        %x{cd #{run_data_path}; 
            mkdir #{run_folder}
        }

        if algorithm.output_type == Algorithm::OUTPUT_TYPE_LOOKUP["3d_volume"]
            AnalysisWorker.perform_async(run_id, 0, 0, 0, 0)
        else
            annotation_points = annotation.data[0][1]["d"].split("M")[1].split("Z")[0].split(" L")
            annotation_points.each do |point|
                point_array = point.split(' ')
                x_coordinates << point_array[0]
                y_coordinates << point_array[1]
            end

            CSV.open(run_data_path + run_folder + "/x_coordinates.csv", "w") do |csv|
                csv << x_coordinates
            end

            CSV.open(run_data_path + run_folder + "/y_coordinates.csv", "w") do |csv|
                csv << y_coordinates
            end

            %x{cd #{algorithm_path};
                matlab -nodisplay -r "tiling('#{image_path}','#{run_data_path + run_folder}', #{TILING_FACTOR}); exit;"
            }

            timer = 0
            until File.exist?(run_data_path + run_folder + '/tiles_to_analyze.json')
                timer +=1
                sleep 1
                if timer > 300
                    break
                end
            end

            tiles_file = File.read(run_data_path + run_folder + '/tiles_to_analyze.json')
            tiles = JSON.parse(tiles_file)
            tiles.each do |tile|
                num_tiles_counter += 1
                tile_x = tile.split(',')[0].to_i
                tile_y = tile.split(',')[1].to_i
                AnalysisWorker.perform_async(run_id, tile_x, tile_y, TILING_FACTOR, TILING_FACTOR)
            end
        end
        run.update_attributes!(:total_tiles=>num_tiles_counter)
    end
  end

end