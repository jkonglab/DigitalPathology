#!bin/env ruby

ENV['RAILS_ENV'] = "production"
require '/DP_Share/imageviewer/config/environment.rb'

user_id = 10

CSV.foreach('/DP_Share/imageviewer/scripts/output.csv') do |image_id|
	ConversionWorker.perform_async(image_id.first.to_i, user_id)
end

