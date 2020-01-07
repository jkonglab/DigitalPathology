class AddOutputFileToResults < ActiveRecord::Migration[5.1]
  def change
	add_column :results, :output_file, :string
  end
end
