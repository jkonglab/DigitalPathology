class AddExcludeToResults < ActiveRecord::Migration[4.2]
  def change
  	add_column :results, :exclude, :boolean
  end
end
