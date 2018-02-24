Paperclip.options[:content_type_mappings] = { :ndpi => 'image/tiff' }
Paperclip::Attachment.default_options.update({
  :hash_secret=> Rails.application.secrets.secret_key_base
})