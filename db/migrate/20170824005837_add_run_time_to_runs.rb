class AddRunTimeToRuns < ActiveRecord::Migration
  def change
  	add_column :runs, :run_at, :integer
  end
end
