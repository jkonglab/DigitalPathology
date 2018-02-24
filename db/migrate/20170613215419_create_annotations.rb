class CreateAnnotations < ActiveRecord::Migration[4.2]
  def change
    create_table :annotations do |t|
    	t.references :image
    	t.json :data
    	t.timestamps
    end
  end
end
