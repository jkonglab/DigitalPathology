class AddCountersToRuns < ActiveRecord::Migration
  def change
  	add_column :runs, :total_tiles, :integer
  	add_column :runs, :tiles_processed, :integer, :default => 0
  end
end
