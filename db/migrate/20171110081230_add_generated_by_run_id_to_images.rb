class AddGeneratedByRunIdToImages < ActiveRecord::Migration[4.2]
  def change
  	add_column :images, :generated_by_run_id, :integer
  end
end
