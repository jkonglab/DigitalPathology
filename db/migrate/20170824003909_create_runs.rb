class CreateRuns < ActiveRecord::Migration[4.2]
  def change
    create_table :runs do |t|
    	t.references :algorithm
    	t.references :image
    	t.references :annotation
    	t.json :parameters
    	t.boolean :processing
   		t.boolean :complete
    	t.timestamps
    end
  end
end
