class ConversionWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3


  def perform(image_id, file_path=nil, force_flag=false)
    image = Image.find(image_id)

    if !image.processing || force_flag
        image.update_attributes!(:processing=>true)

        python_file_path = File.join(Rails.root.to_s, 'python')
        file_path = file_path || image.file_folder_path

        %x{cd #{python_file_path}; 
            source env/bin/activate; 
            cd #{file_path}
            python3 #{python_file_path}/deepzoom_tile.py #{image.file.path}
        }

        dzi_file = File.open(image.dzi_path){ |f| Nokogiri::XML(f) }
        height = dzi_file.css('xmlns|Size').first["Height"]
        width = dzi_file.css('xmlns|Size').first["Width"]

        image.update_attributes!(
            :processing=>false,
            :complete=>true,
            :height => height,
            :width => width)
    end

  end


end