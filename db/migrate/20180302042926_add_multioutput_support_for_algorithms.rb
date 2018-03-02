class AddMultioutputSupportForAlgorithms < ActiveRecord::Migration[5.1]
  def change
  	add_column :algorithms, :multioutput, :boolean, :default => false
  	add_column :algorithms, :multioutput_options, :json
  	add_column :results, :output_key, :string
  	add_column :results, :output_type, :integer
  end
end
