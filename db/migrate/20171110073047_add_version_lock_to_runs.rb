class AddVersionLockToRuns < ActiveRecord::Migration[4.2]
  def change
  	add_column :runs, :lock_version, :integer, :default => 0, :null => false
  end
end
