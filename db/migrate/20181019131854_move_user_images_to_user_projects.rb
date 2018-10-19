class MoveUserImagesToUserProjects < ActiveRecord::Migration[5.1]
  def up
  	create_table :user_project_ownerships do |t|
   	  t.integer :user_id
      t.integer :project_id
    end

    User.all.each do |user|
    	project = Project.new(:title => 'All Images', :privacy => :hidden)
    	project.save!
    	ownership = UserProjectOwnership.new(:project_id=>project.id, :user_id=>user.id)
    	ownership.save!
    end

    Image.all.each do |image|

    	statement = "SELECT project_id FROM user_project_ownerships WHERE user_id = (SELECT user_id FROM user_image_ownerships WHERE image_id = #{image.id} LIMIT 1) LIMIT 1"
    	project_id = ActiveRecord::Base.connection.execute(statement)
  		image.update_attributes!(:project_id => project_id[0]["project_id"])
  	end
  	drop_table :user_image_ownerships
  end

  def down
  	drop_table :user_project_ownerships
  	create_table :user_image_ownerships do |t|
      t.integer :user_id
      t.integer :image_id
    end
  end
end
