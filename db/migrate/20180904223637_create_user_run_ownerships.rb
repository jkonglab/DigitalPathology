class CreateUserRunOwnerships < ActiveRecord::Migration[5.1]
  def change
    create_table :user_run_ownerships do |t|
   	  t.integer :user_id
      t.integer :run_id
    end
  end
end
