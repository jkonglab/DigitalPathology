class AddIndicesToResults < ActiveRecord::Migration[5.1]
  def change
  	add_index(:results, :run_id)
  	add_index(:results, :tile_x)
  	add_index(:results, :tile_y)
  	add_index(:results, :output_key)
  	add_index(:results, :output_type)
  	add_index(:results, :exclude)
  end
end
