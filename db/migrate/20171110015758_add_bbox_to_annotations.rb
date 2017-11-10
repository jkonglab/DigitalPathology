class AddBboxToAnnotations < ActiveRecord::Migration
  def change
  	add_column :annotations, :width, :integer
  	add_column :annotations, :height, :integer
  	add_column :annotations, :x_point, :integer
  	add_column :annotations, :y_point, :integer
  end
end
