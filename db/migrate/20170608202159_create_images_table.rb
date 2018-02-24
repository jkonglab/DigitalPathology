class CreateImagesTable < ActiveRecord::Migration[4.2]
  def change
    create_table :images do |t|
      t.string :title, :default=> ''
      t.integer :height
      t.integer :width
      t.timestamps
    end
  end
end
