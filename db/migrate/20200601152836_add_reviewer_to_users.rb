class AddReviewerToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :reviewer, :integer
  end
end
