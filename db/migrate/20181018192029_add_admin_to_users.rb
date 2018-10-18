class AddAdminToUsers < ActiveRecord::Migration[5.1]
  def change
  	add_column :users, :admin, :integer, :default=> 0
  end
end
