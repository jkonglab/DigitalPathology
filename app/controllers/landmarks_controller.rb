class LandmarksController < ApplicationController

  def create
    @image = Image.find(params[:parent_id])

    ref_image_id = params[:ref_image_id]
    curr_image_id = params[:image_id]
    ref_image_data = JSON.parse(params[:ref_image_data])
    curr_image_data = JSON.parse(params[:image_data])

    ref_points = []
    ref_image_data.each do |point|
        ref_points << [point["x"].to_f.truncate(3),point["y"].to_f.truncate(3)].map(&:to_s)
    end
    
    trgt_points = []
    curr_image_data.each do |point|
        trgt_points << [point["x"].to_f.truncate(3),point["y"].to_f.truncate(3)].map(&:to_s)
    end

    landmark = Landmark.where(:parent_id=> @image.id,:image_id => curr_image_id, :ref_image_id => ref_image_id).first

    if landmark.nil? #create
        new_landmark = Landmark.create!(
            :parent_id => @image.id,
            :image_id => curr_image_id,
            :image_data => trgt_points,
            :ref_image_id => ref_image_id,
            :ref_image_data => ref_points)
        new_landmark.save!
    else
        landmark.destroy
        new_landmark = Landmark.create!(
            :parent_id => @image.id,
            :image_id => curr_image_id,
            :image_data => trgt_points,
            :ref_image_id => ref_image_id,
            :ref_image_data => ref_points)
        new_landmark.save!
    end

end
end