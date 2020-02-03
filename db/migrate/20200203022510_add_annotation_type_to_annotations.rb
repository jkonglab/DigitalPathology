class AddAnnotationTypeToAnnotations < ActiveRecord::Migration[5.1]
  def change
     add_column :annotations, :annotation_type, :string
  end
end
