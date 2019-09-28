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
    python_virtualenv_path = File.join(Rails.root.to_s,'algorithms')
    conversion_file_path = File.join(Rails.root.to_s, 'algorithms', 'conversion')
    file_path = file_path || image.file_folder_path
    if !File.exist?(image.dzi_path)
        if !Rails.application.config.local_processing
            %x{mkdir jobs/#{image.id}}
            File.open("jobs/#{image.id}/job.sh", 'w') do |file|
		file.puts "#!/bin/bash"
                file.puts "#SBATCH -N 1"
                file.puts "#SBATCH -c 4"
                file.puts "#SBATCH -p qDP"
                file.puts "#SBATCH -t 1440"
                file.puts "#SBATCH -J conversion"
                file.puts "#SBATCH -e error%A.err"
                file.puts "#SBATCH -o out%A.out"
                file.puts "#SBATCH -A RS10272"
		file.puts "#SBATCH --mem 8000"
                file.puts "#SBATCH --oversubscribe"
            	file.puts "#SBATCH --uid dbhuvanapalli1"
		file.puts "sleep 7s"
                file.puts "export OMP_NUM_THREADS=4"
                file.puts "export MODULEPATH=/apps/Compilers/modules-3.2.10/Debug-Build/Modules/3.2.10/modulefiles/"
                file.puts "NODE=$(hostname)"
                file.puts "module load Compilers/Python3.7.4"
                file.puts "module load Image_Analysis/Openslide3.4.1"
                file.puts "cd #{python_virtualenv_path}"
                file.puts "source env/bin/activate"
                file.puts "cd #{file_path}"
                file.puts "python3 #{conversion_file_path}/deepzoom_tile.py #{image.file.path}"
	 end

            %x{
		chmod -R 775 jobs/#{image.id};
                cd jobs/#{image.id};
                sbatch job.sh
	      }

       else
            %x{ cd #{python_virtualenv_path}
                source env/bin/activate 
                cd #{file_path}
                python3 #{conversion_file_path}/deepzoom_tile.py #{image.file.path};
            }
        end
    end

    timer = 0

    until File.exist?(image.dzi_path)
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
