class ConversionWorker
  include Sidekiq::Worker
  require 'dicom'
  sidekiq_options :retry => 3


  def perform(image_id, file_path=nil, force_flag=false)
    image = Image.find(image_id)
    image.update_attributes!(:processing=>true)

    ## DICOM READING IS SLOW, REFACTOR TO DO IT ONLY IF FILE EXTENSION IS .dcm
    #dcm = DICOM::DObject.read(image.file.path)
    #if dcm.read?
    #    convert_dicom_to_jpg(image)
    #end

    python_file_path = File.join(Rails.root.to_s, 'python', 'conversion')
    file_path = file_path || image.file_folder_path
    output_file = file_path + '/done'

    if !File.exist?(output_file)
        if !Rails.application.config.local_processing
            %x{mkdir jobs/#{image.id}}
            File.open("jobs/#{image.id}/job.sh", 'w') do |file|
                file.puts "cd #{python_file_path}"
                file.puts "source env/bin/activate"
                file.puts "cd #{file_path}"
                file.puts "python3 #{python_file_path}/deepzoom_tile.py #{image.file.path}"
                file.puts "touch #{output_file}"
            end

            File.open("jobs/#{image.id}/env.sh", 'w') do |file|
                file.puts "module load Compilers/Python3.5"
                file.puts "module load Image_Analysis/Openslide3.4.1"
            end

            %x{ chmod -R 775 jobs/#{image.id};
                cd jobs/#{image.id};
                msub job.sh 4 1 qDP RS10272 P env.sh 8000
            }

        else
            %x{cd #{python_file_path};
            source env/bin/activate;
            cd #{file_path};
            python3 #{python_file_path}/deepzoom_tile.py #{image.file.path} && touch #{output_file};
            }
        end
    end

    timer = 0

    until File.exist?(output_file)
        timer +=1
        sleep 1
        if timer > 900
            break
        end
    end
    
    dzi_file = File.open(image.dzi_path){ |f| Nokogiri::XML(f) }
    height = dzi_file.css('xmlns|Size').first["Height"]
    width = dzi_file.css('xmlns|Size').first["Width"]

    image.update_attributes!(
        :processing=>false,
        :complete=>true,
        :height => height,
        :width => width)

  end

  def convert_dicom_to_jpg(image)
    matlab_path = File.join(Rails.root.to_s, 'algorithms', 'matlab')
    %x{
        cd #{matlab_path}; 
        module load Framework/Matlab2016a;
        matlab -nodisplay -r "dicom2jpg('#{image.file.path}', 2); exit;"
    }
    if File.extname(image.file_file_name) == '.dcm'
        file_base = File.basename(image.file_file_name, File.extname(image.file_file_name))
    else
        file_base = image.file_file_name
    end
    image.update_attributes!(:file_file_name=>file_base + '.jpg', :file_content_type=>'image/jpg')
  end


end