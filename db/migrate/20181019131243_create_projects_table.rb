class CreateProjectsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :projects do |t|
    	t.string :title
    	t.string :privacy
    	t.string :tissue_type
    	t.string :modality
    	t.string :method
    	t.timestamps
    end
  end
end
