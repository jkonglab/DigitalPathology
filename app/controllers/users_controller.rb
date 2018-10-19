class UsersController < ApplicationController
  	before_action :check_admin_user!

	def admin_panel
		query_params = params['q'] || {}
    	query_builder = QueryBuilder.new(query_params)
    	@q = query_builder.to_ransack(Image.where(:parent_id=>nil))
    	@images= @q.result.reorder(query_builder.sort_order)
	end

	def admin_create_user
		@user = User.new
		@resource = @user
	end

	def admin_new_algorithm
		@algorithm = Algorithm.new
	end

	def promote
		@user = User.find(params[:user_id])
		@user.admin = 10
		@user.save
		redirect_back(fallback_location:'/admin')
	end

	def demote
		@user = User.find(params[:user_id])
		@user.admin = 0
		@user.save
		redirect_back(fallback_location:'/admin')
	end

	def create
		@user = User.new(user_params)
		@resource = @user
		if @user.valid?
			@user.save!
			redirect_to '/admin', notice: 'User created, confirmation email sent'
		else
			render :admin_create_user
		end
	end

	def delete
		@user = User.find(params[:user_id])
		@user.destroy
		redirect_to '/admin', notice: 'User deleted.'
	end

	def admin_delete_algorithm
		@algorithm = Algorithm.find(params[:algorithm_id])
		@algorithm.destroy
		redirect_to '/admin', notice: 'Algorithm deleted.'
	end

	def resend_confirmation
		@user = User.find(params[:user_id])
		@user.send_confirmation_instructions
		redirect_to '/admin', notice: 'Confirmation email has been resent'
	end

	private

	  def user_params
	    params.require(:user).permit(:username, :email, :password, :password_confirmation)
	  end

	  def check_admin_user!
    	if !current_user.admin?
    		redirect_to root_path, notice: 'Admins only.'
    	end
  	end
	
end