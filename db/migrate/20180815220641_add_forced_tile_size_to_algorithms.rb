class AddForcedTileSizeToAlgorithms < ActiveRecord::Migration[5.1]
  def change
  	add_column :algorithms, :tile_size, :integer
  end
end
