class AddImageTypeToImages < ActiveRecord::Migration[4.2]
  def change
  	add_column :images, :image_type, :integer, :default => 1
  	add_column :images, :parent_id, :integer
  	add_column :images, :slice_order, :integer
  end
end
