class Image < ActiveRecord::Base
	has_many :annotations
	has_many :runs
  has_many :user_image_ownerships
	has_many :users, :through => :user_image_ownerships
  has_many :results, through: :runs
  has_attached_file :file, {
    path: ":rails_root/public/:url",
    url: "#{Rails.application.config.data_directory}/:id_partition/:hash/:filename",
    hash_data: ":class/:attachment/:id",
    validate_media_type: false
  }

  validates_attachment_content_type :file, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/tiff", "application/octet-stream", "application/dicom"]

  VISIBILITY_PRIVATE = 0
  VISIBILITY_PUBLIC = 1
  IMAGE_TYPE_TWOD = 0
  IMAGE_TYPE_THREED = 1
  IMAGE_TYPE_FOURD = 2

  enum visibility: { hidden: 0, visible: 1 }
  enum image_type: [:twod, :threed, :fourd]
  before_destroy :destroy_children


  def dzi_path
    file_base = File.basename(self.file_file_name, File.extname(self.file_file_name))
    return File.join(self.file_folder_path, file_base + '.dzi')
  end

  def dzi_url
    file_base = File.basename(self.file_file_name, File.extname(self.file_file_name))
    return File.join(file_folder_url, file_base + '.dzi')
  end

  def file_folder_url
    return File.dirname(self.file.url(timestamp: false))
  end

  def file_folder_path
    return File.dirname(self.file.path)
  end

  def tile_folder_path
    file_base = File.basename(self.file_file_name, File.extname(self.file_file_name))
    return File.join(file_folder_path, file_base + '_files')
  end

  def whole_image_path
    file_base = File.basename(self.file_file_name, File.extname(self.file_file_name))
    folder_base = self.height < 500 ? '8' : '11'
    return File.join(self.file_folder_url, file_base + '_files', folder_base, '0_0.jpeg')
  end

  def destroy_children
    self.annotations.destroy_all 
    self.user_image_ownerships.destroy_all   
    self.runs.destroy_all
  end

  def as_json(options = { })
    h = super(options)
    h[:dzi_url] = self.dzi_url
    h
  end

	def self.ransackable_attributes(auth_object = nil)
  		super - ['id', 'created_at', 'format', 'slug', 'path', 'overlap', 'tile_size', 'updated_at', 'file_name_prefix', "user_id"]
	end

  def self.ransackable_scopes(auth_object = nil)
    [:meta_search]
  end
	
  def self.meta_search(*fields)
    query = self

    fields.each do |field_key, field_value|
      query = query.where('images.clinical_data @> ?', Hash[field_key, field_value].to_json)
    end

    query
  end

  def default_tile_size
    if self.width && self.height
      [self.width, self.height].min/100 < 100 ? 100 : [self.width, self.height].min/100
    else
      300
    end
  end

end

