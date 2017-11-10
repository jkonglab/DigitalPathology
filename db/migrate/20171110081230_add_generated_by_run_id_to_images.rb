class AddGeneratedByRunIdToImages < ActiveRecord::Migration
  def change
  	add_column :images, :generated_by_run_id, :integer
  end
end
