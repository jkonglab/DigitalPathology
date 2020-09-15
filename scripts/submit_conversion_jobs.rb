#!bin/env ruby

ENV['RAILS_ENV'] = "production"
require '/Project/DP_Share/imageviewer/config/environment.rb'

user_id = 10

CSV.foreach('/Project/DP_Share/imageviewer/scripts/output.csv') do |image_id|
	ConversionWorker.perform_async(image_id.first.to_i, user_id)
end

