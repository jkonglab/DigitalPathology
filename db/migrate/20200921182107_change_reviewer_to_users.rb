class ChangeReviewerToUsers < ActiveRecord::Migration[5.1]
  def change
	change_column_default :users, :reviewer, 0
  end
end
