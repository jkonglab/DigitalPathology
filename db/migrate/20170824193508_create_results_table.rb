class CreateResultsTable < ActiveRecord::Migration
  def change
    create_table :results do |t|
    	t.references :run
    	t.integer :tile_x
    	t.integer :tile_y
    	t.json    :raw_data
    	t.json	  :svg_data
    	t.integer :run_at
    	t.timestamps
    end
  end
end
