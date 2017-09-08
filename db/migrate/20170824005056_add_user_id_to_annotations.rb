class AddUserIdToAnnotations < ActiveRecord::Migration
  def change
  	add_reference :annotations, :user, index: true
  end
end
