class AddClinicalDataToImages < ActiveRecord::Migration
  def change
  	add_column :images, :clinical_data, :json
  end
end
