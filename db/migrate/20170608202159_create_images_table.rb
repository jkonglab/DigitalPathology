class CreateImagesTable < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :title, :default=> ''
      t.string :slug
      t.string :format
      t.string :path, :null=>false
      t.integer :overlap
      t.integer :tile_size
      t.integer :height
      t.integer :width
      t.timestamps
    end
  end
end
