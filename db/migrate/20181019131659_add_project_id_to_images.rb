class AddProjectIdToImages < ActiveRecord::Migration[5.1]
  def change
  	add_column :images, :project_id, :integer
  end
end
