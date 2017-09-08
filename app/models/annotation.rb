class Annotation < ActiveRecord::Base
	belongs_to :image
	belongs_to :user
	has_many :runs
end