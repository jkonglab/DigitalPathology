class Run < ActiveRecord::Base
	belongs_to :image
	belongs_to :annotation
	belongs_to :algorithm
	belongs_to :user
	has_many :results

	before_destroy :destroy_children

	def destroy_children
		self.results.delete_all
	end

	def check_if_done
		if (self.total_tiles == 0 || (self.tiles_processed >= self.total_tile))
			self.update_attributes!(:processing=>false, :complete=>true)
		end
	end

	def run_folder
    	run_data_path = File.join(Rails.root.to_s, 'algorithms', 'run_data')
    	run_folder = 'run_' + self.id.to_s + '_' + self.run_at.to_s
    	File.join(run_data_path, run_folder)
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