class Convert3dWorker
    include Sidekiq::Worker
    require 'json'
    attr_accessor :run, :image, :annotation, :algorithm
    sidekiq_options :retry => 3

    def perform(parent_id, user_id)
        conversion_file_path = File.join(Rails.root.to_s,'algorithms','python3','conversion')
        puts "Parent Id =>"
        puts parent_id
        puts "convert 3d worker is running"
        image_ids = Image.where(:parent_id => parent_id).pluck('id')
        puts "Image id =>"
        puts image_ids
        for id in image_ids do
            puts "id =>"
            puts id 
            image = Image.find(id)
            puts image.file_folder_path
            %x{ 
                source ~/opt/anaconda3/etc/profile.d/conda.sh
                conda activate test
                python3 --version
                cd #{image.file_folder_path}
                python3 #{conversion_file_path}/image_convert.py #{image.file.path};
            }
        end
    end
end