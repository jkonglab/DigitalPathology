class Run < ActiveRecord::Base
	belongs_to :image
	belongs_to :annotation
	belongs_to :algorithm
	belongs_to :user
	has_many :results

	before_destroy :destroy_children_and_jobs

	def destroy_children_and_jobs
		self.results.delete_all
		queue = Sidekiq::Queue.new("user_analysis_queue_" + self.user_id.to_s)
		queue.each do |job|
		  job.delete if job.args[0] == self.id && job.klass == 'AnalysisWorker'
		end
		queue = Sidekiq::Queue.new("single_analysis_queue")
		queue.each do |job|
		  job.delete if job.args[0] == self.id && job.klass == 'AnalysisWorker'
		end
	end

	def check_if_done
		if (self.total_tiles == 0 || (self.total_tiles && self.tiles_processed >= self.total_tiles))
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


  	def annotation()
    	h = super
    	if self.annotation_id == 0
    		h = self.image.annotations.new(:label=> 'Whole Slide')
    	end
    	h
  	end
end