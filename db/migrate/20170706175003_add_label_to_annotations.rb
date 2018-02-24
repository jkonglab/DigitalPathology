class AddLabelToAnnotations < ActiveRecord::Migration[4.2]
  def change
  	add_column :annotations, :label, :string
  end
end
