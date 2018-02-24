class CreateAlgorithmTitle < ActiveRecord::Migration[4.2]
  def change
    add_column :algorithms, :title, :string
  end
end
