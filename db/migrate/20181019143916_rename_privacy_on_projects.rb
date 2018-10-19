class RenamePrivacyOnProjects < ActiveRecord::Migration[5.1]
  def change
  	rename_column :projects, :privacy, :visibility
  end
end
