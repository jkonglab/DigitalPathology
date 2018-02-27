# How to use
# 1. Set files_reg_expression to the folder and wildcard needed to 
#    pick up all the files you want to convert & attach
#
# 2. If necessary, change the convert_file_path_to_new_filename function to get the 
#    filename you want based on the old filename

files_reg_expression = './public/dp-data/*.svs'

files = Dir.glob(files_reg_expression)

files.each do |image_path|
    @image = Image.create(:file => File.open(image_path, 'rb'))
	@image.title = convert_file_path_to_new_filename(image_path)
	@image.image_type = Image::IMAGE_TYPE_TWOD
 	UserImageOwnership.create!(:user_id=> 1,:image_id=> @image.id)
	@image.save
	ConversionWorker.perform_async(@image.id)
end

def convert_file_path_to_new_filename(image_path)
	return '3d_Nuclei_GBM_Oct07_2014_slice_' + image_path.split('/')[-1].split('-')[0][0..-2]
end
