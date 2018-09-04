class UserImageOwnershipsController < ApplicationController
  autocomplete :user, :email
  before_action :set_images_validated, :only =>[:confirm_share, :create]


  def confirm_share
  	@ownership = UserImageOwnership.new
  end

  def create
    user = User.where("lower(email) = ?", params[:user_image_ownership][:user_id].downcase)
    length = @images.length
    if user.count > 0
      @images.each do |image|
        UserImageOwnership.find_or_create_by!(:user_id=>user[0].id, :image_id=>image.id)
      end
      return redirect_to my_images_images_path, notice: "#{length} images shared with #{user[0].email}"
    else
      redirect_to my_images_images_path, alert: 'Could not find user to share with'
    end
  end

  private

  def set_images_validated
    image_ids = params['image_ids']
    if !image_ids
      redirect_to my_images_images_path, alert: 'No images selected'
    else
      @images = current_user.images.where('images.id IN (?)', image_ids)
      if @images.length < 1
        redirect_to my_images_images_path, alert: 'No images selected or you may lack permission to edit these images'
      end
    end     
  end

end
