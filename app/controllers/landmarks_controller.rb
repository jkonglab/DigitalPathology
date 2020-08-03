class LandmarksController < ApplicationController

  def create
    @image = Image.find(params[:parent_id])

    ref_image_id = params[:ref_image_id]
    curr_image_id = params[:image_id]
    ref_image_data = JSON.parse(params[:ref_image_data])
    curr_image_data = JSON.parse(params[:image_data])

    landmark = Landmark.where(:image_id => curr_image_id, :ref_image_id => curr_image_id)

    if landmark.first.nil? #create
      l = Landmark.new
      l.parent_id = @image.id
      l.image_id = curr_image_id
      l.image_data = curr_image_data
      l.ref_image_id = ref_image_id
      l.ref_image_data = ref_image_data
      l.save
    else
      landmark.update_all({
        :image_data => curr_image_data,
        :ref_image_data => ref_image_data
      })
    end

  end
  
end