class AddClassToAnnotations < ActiveRecord::Migration[5.1]
  def change
    add_column :annotations, :class, :string
  end
end
