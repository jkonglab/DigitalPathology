class Image < ActiveRecord::Base
	has_many :annotations
	has_many :runs
	belongs_to :user
end