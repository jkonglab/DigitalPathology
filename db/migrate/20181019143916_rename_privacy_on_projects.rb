class RenamePrivacyOnProjects < ActiveRecord::Migration[5.1]
  def change
  	rename_column :projects, :privacy, :visibility
  	change_column :projects, :visibility, 'integer USING CAST(visibility AS integer)'
  end
end
