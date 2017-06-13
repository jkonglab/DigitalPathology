class ChangeConfusingColumnName < ActiveRecord::Migration
  def change
  	rename_column :images, :uploaded_file_name, :original_file_name
  end
end
