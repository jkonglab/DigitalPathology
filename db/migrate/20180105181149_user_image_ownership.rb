class UserImageOwnership < ActiveRecord::Migration
  def change
  	create_table :user_image_ownerships do |t|
      t.integer :user_id
      t.integer :image_id
    end
  end
end
