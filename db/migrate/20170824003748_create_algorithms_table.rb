class CreateAlgorithmsTable < ActiveRecord::Migration
  def change
    create_table :algorithms do |t|
      t.string :name
      t.json :parameters
    end
  end
end
