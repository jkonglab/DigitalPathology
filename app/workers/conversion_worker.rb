class ConversionWorker
  include Sidekiq::Worker

  def perform(image_id)
    image = Image.find(image_id)

    if image.path.blank? && !image.processing
        image.update_attributes!(:processing=>true)

        python_file_path = Rails.root.to_s + '/python'
        data_file_path = Rails.root.to_s + '/public/data'
        file_name = image.upload_file_name
        file_name_suffix = file_name.split('.')[-1]
        file_name_prefix = file_name.split('.' + file_name_suffix)[0]

        %x{cd #{python_file_path}; 
            source env/bin/activate; 
            cd #{data_file_path};
            mkdir #{file_name_prefix};
            cd #{file_name_prefix};
            python3 #{python_file_path}/deepzoom_tile.py ../#{file_name}}

        image.update_attributes!(
            :format=>'jpeg', 
            :path=> '/data/' + file_name_prefix + '/' + file_name_prefix + '_files' + '/',
            :file_name_prefix => file_name_prefix,
            :processing=>false)
    end

  end


end