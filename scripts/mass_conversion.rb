#!bin/env ruby
require 'fileutils'
# How to use
# 1. Set orig_files_reg_expression to the folder and wildcard needed to 
#    pick up all the files you want to convert & attach
#
# 2. Have a temporary file in temp_file path, with the same format as images to be processed
#
# 3. Change userid and projectid
#
# 4. For executing the script
#    cd /DP_Share/imageviewer/scripts
#    ruby mass_conversion.rb
#
# 5. This script will attach a temporary file and creates image record in db
# -creates a script to copy actual images
# -creates a script with list of commands to be executed to convert the image on hpc
# -creates an output file with new image ids which will be used by the database update script
#
# 6. After the images are convert, execute db_update_script
#
# 7. Also remove the output, copy, conversion script after done or before starting

ENV['RAILS_ENV'] = "development"
require '/Users/ohm/imageviewer/config/environment.rb'

orig_files_reg_expression = '/Users/ohm/imageviewer/test_dataset/*.png'
user_id = 1
project_id = 1
files = Dir.glob(orig_files_reg_expression)
temp_file_path = '/Users/ohm/imageviewer/test_dataset'
temp_file = '/Users/ohm/imageviewer/test_dataset/test_image.png'
output_file = '/Users/ohm/imageviewer/scripts/output.csv'
copy_script_file = '/Users/ohm/imageviewer/scripts/copy.sh'
conversion_script_file = '/Users/ohm/imageviewer/scripts/conversion.sh'

files.each do |image_path|
	title = image_path.split('/')[-1]
	new_file = File.join(temp_file_path, title)
	FileUtils.cp(temp_file, new_file)
	@image = Image.create(:file => File.open(new_file, 'rb'))
	@image.title = title
	@image.image_type = Image::IMAGE_TYPE_TWOD
	@image.project_id = project_id
 	#UserProjectOwnership.create!(:user_id=> user_id,:project_id=> project_id)
	@image.save
	#ConversionWorker.perform_async(@image.id, user_id)
	CSV.open(output_file, "a+") do |csv|
		csv << [@image.id]
	end
	File.open(copy_script_file, "a+") do |f|
		f.puts "cp #{image_path} #{@image.file.path}"
	end
	File.open(conversion_script_file, "a+") do |f|
                f.puts "module load Compilers/Python3.7.4"
		f.puts "module load Image_Analysis/Openslide3.4.1"
		f.puts "cd /Users/ohm/imageviewer/algorithms/python3"
		# f.puts "source env3.7/bin/activate"
		f.puts "cd #{@image.file_folder_path}"
		f.puts "python3 /Users/ohm/imageviewer/algorithms/python3/conversion/deepzoom_tile.py #{@image.file.path}"
		f.puts ""
        end
	# temp_file = new_file
end



