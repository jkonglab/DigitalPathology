ENV['RAILS_ENV']="development"
require '/Users/ohm/imageviewer/config/environment.rb'
require 'fileutils'
require 'csv'

input_file = '/Users/ohm/imageviewer/scripts/input.csv'
conversion_file_3d = '/Users/ohm/imageviewer/scripts/3d_conversion.sh'

CSV.foreach(input_file) do |image_id|
    @image = Image.find(image_id).first
    File.open(conversion_file_3d, "a+") do |f|
        f.puts "cd #{@image.file_folder_path}"
        f.puts "python3 /Users/ohm/imageviewer/algorithms/python3/conversion/image_convert.py #{@image.file.path}"
		f.puts ""
        end
end
  










