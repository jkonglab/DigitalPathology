class AddTileSizeToRuns < ActiveRecord::Migration
  def change
  	add_column :runs, :tile_size, :integer
  end
end
