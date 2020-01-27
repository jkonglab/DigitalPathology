class RenameClassToAnnotationClassInAnnotation < ActiveRecord::Migration[5.1]
  def change
	rename_column :annotations, :class, :annotation_class
  end
end
