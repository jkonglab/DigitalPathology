class Image < ActiveRecord::Base
	has_many :annotations
	has_many :runs
	belongs_to :user

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

