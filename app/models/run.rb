class Run < ActiveRecord::Base
	belongs_to :image
	belongs_to :annotation
	belongs_to :algorithm
	belongs_to :user
	has_many :results

	before_destroy :destroy_children

	def destroy_children
		self.results.destroy_all
	end

	def status_words
		if self.complete
			return 'Complete'
		elsif self.processing
			return "Processing (#{self.tiles_processed}/#{self.total_tiles || '?'})"
		else
			return 'In Queue'
		end
	end
end