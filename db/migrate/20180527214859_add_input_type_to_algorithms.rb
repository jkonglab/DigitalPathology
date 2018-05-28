class AddInputTypeToAlgorithms < ActiveRecord::Migration[5.1]
  def change
  	add_column :algorithms, :input_type, :integer, :default => 0
  end
end
