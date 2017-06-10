class AddFileProcessingDataToImages < ActiveRecord::Migration
  def change
  	add_column :images, :processing, :boolean, :default=> false
  	add_column :images, :uploaded_file_name, :string
  	change_column :images, :path, :string, :null => true
  end
end
