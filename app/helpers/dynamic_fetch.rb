require 'sidekiq/fetch'

class DynamicFetch < Sidekiq::BasicFetch

  def queues_cmd
  	if @strictly_ordered_queues
        @queues
  	else
    	queues = Sidekiq.redis { |conn| conn.smembers('queues') }
    	queues.map! { |q| "queue:#{q}" }
    	if queues.empty?
      		return super
    	else
      		queues = queues.shuffle.uniq
        	queues << TIMEOUT
        	queues
    	end
    end
  end
  
end
