class CreateClinicalData < ActiveRecord::Migration
  def change
    create_table :clinical_data do |t|
      t.integer :image_id
      t.string :meta_key
      t.string :meta_value

      t.timestamps null: false
    end
  end
end
