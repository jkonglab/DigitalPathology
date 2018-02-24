class AddFileProcessingDataToImages < ActiveRecord::Migration[4.2]
  def change
  	add_column :images, :processing, :boolean, :default=> false
  	add_column :images, :complete, :boolean, :default=> false
  end
end
