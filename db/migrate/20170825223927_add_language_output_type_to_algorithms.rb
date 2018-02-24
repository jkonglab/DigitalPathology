class AddLanguageOutputTypeToAlgorithms < ActiveRecord::Migration[4.2]
  def change
  	add_column :algorithms, :language, :integer
  	add_column :algorithms, :output_type, :integer
  end
end
