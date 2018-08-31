class SingleQueueFlag < ActiveRecord::Migration[5.1]
  def change
  	add_column :algorithms, :single_queue_flag, :boolean
  end
end
