class AddPrivacyToImages < ActiveRecord::Migration
  def change
  	add_column :images, :visibility, :integer, :default=> 0
  end
end
