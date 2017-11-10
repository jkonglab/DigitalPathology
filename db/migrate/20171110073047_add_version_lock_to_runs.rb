class AddVersionLockToRuns < ActiveRecord::Migration
  def change
  	add_column :runs, :lock_version, :integer, :default => 0, :null => false
  end
end
