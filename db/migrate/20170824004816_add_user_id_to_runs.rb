class AddUserIdToRuns < ActiveRecord::Migration[4.2]
  def change
  	add_reference :runs, :user, index: true
  end
end
