class ClinicalDataController < ApplicationController


	def create
		json_file = params[:clinical_datum][:upload].read
		image_id = params[:clinical_datum][:image_id]

		json_hash = JSON.parse(json_file) #returns hash
		json_hash.each do |key,value|
			ClinicalDatum.create(image_id: image_id, meta_key: key, meta_value: value)
		end
		redirect_to :back
	end 


end
