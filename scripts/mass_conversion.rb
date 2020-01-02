#!bin/env ruby
# How to use
# 1. Set files_reg_expression to the folder and wildcard needed to 
#    pick up all the files you want to convert & attach
#
# 2. If necessary, change the convert_file_path_to_new_filename function to get the 
#    filename you want based on the old filename
#
# 3. Change userid and projectid
#
# 4. For executing the script
#    cd /DP_Share/imageviewer/scripts
#    ruby mass_conversion.rb

ENV['RAILS_ENV'] = "production"
require '/DP_Share/imageviewer/config/environment.rb'

files_reg_expression = '/DP_Share/Testing_WSIs/Temp/*.tif'
user_id = 10
project_id = 18
files = Dir.glob(files_reg_expression)

files.each do |image_path|
        @image = Image.create(:file => File.open(image_path, 'rb'))
	@image.title = image_path.split('/')[-1]
	@image.image_type = Image::IMAGE_TYPE_TWOD
	@image.project_id = project_id
 	#UserProjectOwnership.create!(:user_id=> user_id,:project_id=> project_id)
	@image.save
	ConversionWorker.perform_async(@image.id, user_id)
end



