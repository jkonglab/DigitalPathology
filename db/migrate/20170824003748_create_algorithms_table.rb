class CreateAlgorithmsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :algorithms do |t|
      t.string :name
      t.json :parameters
    end
  end
end
