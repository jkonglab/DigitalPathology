class ChangeConfusingColumnName < ActiveRecord::Migration
  def change
  	rename_column :images, :original_file_name, :upload_file_name
  end
end
