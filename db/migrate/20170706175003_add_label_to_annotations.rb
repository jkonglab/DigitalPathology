class AddLabelToAnnotations < ActiveRecord::Migration
  def change
  	add_column :annotations, :label, :string
  end
end
