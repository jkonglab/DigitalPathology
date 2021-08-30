class AddPercentageResultsToRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :runs, :percentage, :decimal
  end
end
