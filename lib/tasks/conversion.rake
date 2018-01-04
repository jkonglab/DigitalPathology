require "pathname"

namespace :conversion do
  desc "Accesses an absolute path of SVS folders and uploads and converts the SVSes to DZI"

  task :upload_and_convert_from_folder, [:path, :user_id] => :environment do |task, args|
  	user_id = args.user_id
  	path = args.path
	sub_folders = Pathname.new(path).children.select { |c| c.directory? }.collect { |p| p.to_s }

	sub_folders.each do |sub_folder|
  		%x{cd #{path}/#{sub_folder}
  		};
	end
  		original_filename = #Find a file ending in .svs
  		#Copy it over to the data directory
  		image = Image.create_new_image(original_filename, user_id)
  		# Rename it to image.upload_file_name



  end
end
