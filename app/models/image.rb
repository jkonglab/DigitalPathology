class Image < ActiveRecord::Base
	has_many :annotations
	has_many :runs
  has_many :user_image_ownerships
	has_many :users, :through => :user_image_ownerships
  has_many :results, through: :runs

  VISIBILITY_PRIVATE = 0
  VISIBILITY_PUBLIC = 1
  IMAGE_TYPE_TWOD = 0
  IMAGE_TYPE_THREED = 1
  IMAGE_TYPE_FOURD = 2

  enum visibility: { hidden: 0, visible: 1 }
  enum image_type: [:twod, :threed, :fourd]
  after_create :create_user_image_ownership
  before_destroy :destroy_children

  def self.create_new_image(original_filename, user_id)
    original_filename = original_filename.gsub(' ', '_')
    image_suffix = original_filename.split('.')[-1]
    image_title = original_filename.split('.'+image_suffix)[0]
    image_unique_id = Image.last ? Image.last.id + 1 : 2
    random_hash = ('a'..'z').to_a.shuffle[0,8].join
    new_file_name = random_hash + '-' + image_title + '-' + image_unique_id.to_s + '.' + image_suffix
    image = Image.create(
      :title => image_title, 
      :upload_file_name => new_file_name, 
      :user_id=>user_id, 
      :image_type => Image::IMAGE_TYPE_TWOD)
  
    return image
  end

  def destroy_children
    self.annotations.destroy_all 
    self.user_image_ownerships.destroy_all   
    self.results.destroy_all
    self.runs.destroy_all
  end

  def create_user_image_ownership
    return UserImageOwnership.create!(
      :user_id=>self.user_id,
      :image_id=>self.id)
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

end

