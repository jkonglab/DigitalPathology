class AddPercentageAnalyisDoneToRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :runs, :percentage_analysis_done, :boolean
  end
end
