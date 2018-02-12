class ConversionWorker
  include Sidekiq::Worker

  def perform(image_id, data_file_path=nil, force_flag=false)
    image = Image.find(image_id)

    if (image.path.blank? && !image.processing) || force_flag
        image.update_attributes!(:processing=>true)

        python_file_path = Rails.root.to_s + '/python'
        data_file_path = data_file_path || Rails.root.to_s + '/public/' + Rails.application.config.data_directory
        file_name = image.upload_file_name
        file_name_suffix = file_name.split('.')[-1]
        file_name_prefix = "#{file_name.split('.' + file_name_suffix)[0]}"

        %x{cd #{python_file_path}; 
            source env/bin/activate; 
            cd #{data_file_path};
            mkdir #{file_name_prefix};
            cd #{file_name_prefix};
            python3 #{python_file_path}/deepzoom_tile.py ../#{file_name}
            mv ../#{file_name_prefix} #{Rails.root.to_s + '/public/' + Rails.application.config.data_directory}}

        dzi_file = File.open(Rails.root.to_s + '/public/' + Rails.application.config.data_directory + "/#{file_name_prefix}" + "/#{file_name_prefix}.dzi") { |f| Nokogiri::XML(f) }
        height = dzi_file.css('xmlns|Size').first["Height"]
        width = dzi_file.css('xmlns|Size').first["Width"]

        image.update_attributes!(
            :format=>'jpeg', 
            :path=> '/' + Rails.application.config.data_directory + '/' + file_name_prefix + '/' + file_name_prefix + '_files' + '/',
            :file_name_prefix => file_name_prefix,
            :processing=>false,
            :height => height,
            :width => width)
    end

  end


end