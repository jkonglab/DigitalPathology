require 'json'
class PRWorker
    include Sidekiq::Worker
    require 'csv'
    attr_accessor :run, :image, :annotation, :algorithm
    sidekiq_options :retry => 3

    def perform(run_id, user_id)
        puts "pr_worker is running"
        puts run_id
        @run = Run.find(run_id)
        puts (run.run_folder)
        @image = Image.find(@run.image_id)
        @annotation = Annotation.find(@run.annotation_id)
        @output_file = @run.run_folder + "/pr_result.json"	
        create_annotation_file(annotation)
    end

    def create_annotation_file(annotation)
        puts "annotation"
        puts annotation.label
        output = []
        result_hash = {}
        result_hash["name"] = annotation.label
        result_hash["annotation_class"] = annotation.annotation_class
        puts result_hash["name"]
        annotation_data_arr = []
        annotation_data = {}
        if annotation.data[0][0] == "path"
            points = []
            puts annotation.data[0][1]["d"].include? "L"
            if annotation.data[0][1]["d"].include? "L"
                annotation_data["annotation_object"] = "contour"
                annotation_points = annotation.data[0][1]["d"].split("M")[1].split("Z")[0].split(" L")
                annotation_points.each do |point|
                    point_array = point.split(' ')
                    points << [(((point_array[0].to_f)*@image.width)/100).to_i, (((point_array[1].to_f)*@image.height)/100).to_i]
                end
            else
                annotation_data["annotation_object"] = "point"
                annotation_points = annotation.data[0][1]["d"].split("M")[1].split("Z")[0]
                point_array = annotation_points.split(' ')
                points << [(((point_array[0].to_f)*@image.width)/100).to_i, (((point_array[1].to_f)*@image.height)/100).to_i]
            end
            annotation_data["bbox_coordinates"] = [annotation.x_point, annotation.y_point]
            annotation_data["bbox_width"] = annotation.width
            annotation_data["bbox_height"] = annotation.height
            annotation_data["absolute_coordinates"] = points
        elsif annotation.data[0][0] == "rect"
            annotation_data["annotation_object"] = "rectangle"
            annotation_data["bbox_coordinates"] = [annotation.x_point, annotation.y_point]
            annotation_data["bbox_width"] = annotation.width
            annotation_data["bbox_height"] = annotation.height
            rectx_coord = (((annotation.data[0][1]["x"].to_f)*@image.width)/100).to_i
            recty_coord = (((annotation.data[0][1]["y"].to_f)*@image.height)/100).to_i
            points = []
            points[0] = [rectx_coord, recty_coord]
            points[1] = [(rectx_coord + annotation.width) , recty_coord]
            points[2] = [rectx_coord, (recty_coord + annotation.height)]
            points[3] = [(rectx_coord + annotation.width), (recty_coord + annotation.height)]
            annotation_data["absolute_coordinates"] = points
            annotation_data["width"] = (((annotation.data[0][1]["width"].to_f)*@image.width)/100).to_i 
            annotation_data["height"] = (((annotation.data[0][1]["height"].to_f)*@image.height)/100).to_i 
        # elsif a.data[0][0] == "circle"
        #     annotation_data["annotation_object"] = "circle"
        #     annotation_data["bbox_coordinates"] = [a.x_point, a.y_point]
        #     annotation_data["bbox_width"] = a.width
        #     annotation_data["bbox_height"] = a.height
        #     annotation_data["center_coordinates"] = [(((a.data[0][1]["cx"].to_f)*@image.width)/100).to_i , (((a.data[0][1]["cy"].to_f)*@image.height)/100).to_i]
            # annotation_data["radius"] = (((a.data[0][1]["r"].to_f)*@image.width)/100).to_i 
        end
        annotation_data["annotation_type"] = annotation.annotation_type
        annotation_data_arr << annotation_data
        result_hash["annotations"] = annotation_data_arr
        output << result_hash
        annotation_file = File.join(@run.run_folder, "/annotation.json")
        File.open(annotation_file,"w") do |f|
            f.write(output.to_json)

        # puts "annotation file was created!"
        # output.json
        end
        # create_result_file()
    end

    def create_result_file() 
        @results = @run.results.where('exclude IS NOT true').order('output_key asc, id asc')
        @algorithm = @run.algorithm
        output = []
        if @algorithm.output_type != Algorithm::OUTPUT_TYPE_LOOKUP["image"]
            puts('here')
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
              results_file = File.join(@run.run_folder, "/result_to_parse.json")
              File.open(results_file,"w") do |f|
                f.write(output.to_json)
            end
            print('print algorithm path => ')
        print(algorithm_path)
        print('test')
        puts @output_file
        %x{
            cd #{algorithm_path};
            python3 pr_analysis.py #{run.run_folder} #{run.tile_size}
        }
        timer = 0
        until File.exist?(@output_file)
            timer +=1
            sleep 1
            if timer > 3600
                break
            end
        end
        # if File.exist?(@output_file)
        #     output_json = File.read(@output_file)
        #     output_hash = JSON.parse(output_json)
        #     puts "output hash =>"
        #     puts output_hash 
        # end 
        puts " #{@output_file} has been created successfully "
        end
    end

    def algorithm_path
        return File.join(Rails.root.to_s, 'algorithms', 'python3')
    end

end
  