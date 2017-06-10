class ConversionWorker
  include Sidekiq::Worker

  def perform(image_id)
    image = Image.find(image_id)

    if image.path.blank? && !image.processing
        image.update_attributes!(:processing=>true)

        python_file_path = Rails.root.to_s + '/python/data'
        file_name = image.upload_file_name
        file_name_suffix = file_name.split('.')[-1]
        file_name_prefix = file_name.split('.' + file_name_suffix)[0]
        amazon_path = 'https://s3.amazonaws.com/' + Rails.application.config.s3_bucket + '/'

        %x{cd #{python_file_path}; 
            source ../env/bin/activate; 
            mkdir #{file_name_prefix};
            cd #{file_name_prefix};
            python3 ../../deepzoom_tile.py ../#{file_name};
            aws s3 sync . s3://#{Rails.application.config.s3_bucket}/#{file_name_prefix} --acl public-read}

        image.update_attributes!(
            :format=>'jpeg', 
            :path=> amazon_path + file_name_prefix + '/' + file_name_prefix + '_files' + '/',
            :overlap=> 1,
            :tile_size=>254,
            :height=>20747,
            :width=>24001,
            :processing=>false)
    end

  end


end
