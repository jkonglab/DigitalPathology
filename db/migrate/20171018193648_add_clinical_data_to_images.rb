class AddClinicalDataToImages < ActiveRecord::Migration[4.2]
  def change
  	add_column :images, :clinical_data, :json
  end
end
