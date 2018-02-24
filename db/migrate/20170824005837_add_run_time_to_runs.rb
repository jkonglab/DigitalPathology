class AddRunTimeToRuns < ActiveRecord::Migration[4.2]
  def change
  	add_column :runs, :run_at, :integer
  end
end
