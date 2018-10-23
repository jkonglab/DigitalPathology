class ConversionWorker
  include Sidekiq::Worker
  require 'dicom'
  sidekiq_options :retry => 3


  def perform(image_id, file_path=nil, force_flag=false)
    image = Image.find(image_id)

    if !image.processing || force_flag
        image.update_attributes!(:processing=>true)

        dcm = DICOM::DObject.read(image.file.path)
        if dcm.read?
            convert_dicom_to_jpg(image)
        end

        python_file_path = File.join(Rails.root.to_s, 'python')
        file_path = file_path || image.file_folder_path
        output_file = file_path + '/done'

        %x{cd #{python_file_path}; 
            source env/bin/activate; 
            cd #{file_path}
            python3 #{python_file_path}/deepzoom_tile.py #{image.file.path}
            touch #{output_file}
        }

        timer = 0
        until File.exist?(output_file)
            timer +=1
            sleep 1
            if timer > 300
                break
            end
        end

        %x{rm #{output_file}}
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

  def convert_dicom_to_jpg(image)
    matlab_path = File.join(Rails.root.to_s, 'algorithms', 'matlab')
    %x{cd #{matlab_path}; matlab -nodisplay -r "dicom2jpg('#{image.file.path}', 2); exit;"}
    if File.extname(image.file_file_name) == '.dcm'
        file_base = File.basename(image.file_file_name, File.extname(image.file_file_name))
    else
        file_base = image.file_file_name
    end
    image.update_attributes!(:file_file_name=>file_base + '.jpg', :file_content_type=>'image/jpg')
  end


end