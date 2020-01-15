#!bin/env ruby

ENV['RAILS_ENV'] = "production"
require '/DP_Share/imageviewer/config/environment.rb'
images = [718,714,747,746,745,744,743,742,741,740,739,738,737,736,735,734,733,725]

CSV.foreach('/DP_Share/imageviewer/scripts/output.csv') do |image_id|
         @image = Image.find(image_id)
         dzi_file = File.open(@image.dzi_path){ |f| Nokogiri::XML(f) }
         @image.height = dzi_file.css('xmlns|Size').first["Height"]
         @image.width = dzi_file.css('xmlns|Size').first["Width"]
	 @image.processing = false
	 @image.complete = true
	 @image.save
end
