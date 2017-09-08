class AddLanguageOutputTypeToAlgorithms < ActiveRecord::Migration
  def change
  	add_column :algorithms, :language, :integer
  	add_column :algorithms, :output_type, :integer
  end
end
