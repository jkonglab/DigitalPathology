class AddUserIdToAnnotations < ActiveRecord::Migration[4.2]
  def change
  	add_reference :annotations, :user, index: true
  end
end
