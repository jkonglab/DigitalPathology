ENV['RAILS_ENV'] = "development"
require '/Users/ohm/imageviewer/config/environment.rb'
require 'fileutils'
require 'csv'

input_file = '/Users/ohm/imageviewer/scripts/input.csv'
volume_vti_file = '/Users/ohm/imageviewer/scripts/volume_vti.sh'
image_path_file = "/Users/ohm/imageviewer/scripts/file_path.csv"

counter = 0
CSV.foreach(input_file) do |image_id|
    @image = Image.find(image_id).first
    File.open(image_path_file, "a+") do |f|
        if counter == 0
            File.open(volume_vti_file, "a+") do |f|
                f.puts "cd /Users/ohm/imageviewer/public/#{Rails.application.config.data_directory}/test_images"
                f.puts "mkdir #{@image.parent_id}"
                f.puts ""
                counter = counter + 1
            end

        end
        file_base = File.basename(@image.file_file_name, File.extname(@image.file_file_name))
        file_image_path = File.join(@image.file_folder_url, file_base + '_3d_view', '0_0.png')
        f.puts "/Users/ohm/imageviewer/public/#{file_image_path}"
    end
end
File.open(volume_vti_file, "a+") do |f|
    f.puts "cd /Users/ohm/imageviewer/public/#{Rails.application.config.data_directory}/test_images/#{@image.parent_id}"
    f.puts "python3 /Users/ohm/imageviewer/algorithms/python3/conversion/volume_render.py #{image_path_file}"
end
    