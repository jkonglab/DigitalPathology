class CreateAlgorithmTitle < ActiveRecord::Migration
  def change
    add_column :algorithms, :title, :string
  end
end
