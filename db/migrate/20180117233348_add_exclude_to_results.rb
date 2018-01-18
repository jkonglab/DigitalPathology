class AddExcludeToResults < ActiveRecord::Migration
  def change
  	add_column :results, :exclude, :boolean
  end
end
