class AddFileNamePrefixToImages < ActiveRecord::Migration
  def change
  	add_column :images, :file_name_prefix, :string
  end
end
