class ChangeFileSizeInImage < ActiveRecord::Migration[5.1]
  def change
	change_column :images, :file_file_size, :bigint
  end
end
