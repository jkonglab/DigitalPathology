class AddTileSizeToRuns < ActiveRecord::Migration[4.2]
  def change
  	add_column :runs, :tile_size, :integer
  end
end
