class Result < ActiveRecord::Base
	belongs_to :run
	belongs_to :user
	belongs_to :image
end