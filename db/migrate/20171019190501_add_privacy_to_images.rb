class AddPrivacyToImages < ActiveRecord::Migration[4.2]
  def change
  	add_column :images, :visibility, :integer, :default=> 0
  end
end
