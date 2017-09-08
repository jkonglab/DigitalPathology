class Run < ActiveRecord::Base
	belongs_to :image
	belongs_to :annotation
	belongs_to :algorithm
	belongs_to :user
	has_many :results
end