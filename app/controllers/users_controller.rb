class UsersController < ApplicationController
    before_action :check_admin_user!
    respond_to :html, :json

  def approve
    @user = User.find(params[:user_id])
    @user.approved = true
    @user.save
    ApprovalMailer.approval_notification(@user.email).deliver
    redirect_back(fallback_location:'/admin')
  end

  def admin_panel
    query_params = params['q'] || {}
      query_builder = QueryBuilder.new(query_params)
      @q = query_builder.to_ransack(Project.all)
      @projects= @q.result.reorder(query_builder.sort_order)
  end

  def admin_create_user
    @user = User.new
    @resource = @user
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

  def get_sidekiq_log
    puts "got triggered"
  end

  def get_analysis_log
    @logs = []
    puts "analysis_log_file =>"
    puts log_file
    if File.exist?(log_file)
      if File.zero?(log_file)
        @logs.push("Log is empty")
      else
        File.readlines(log_file).each do |line|
          puts line
          @logs.push(line)
        end
      end
    else
       @logs.push("Log is empty")
    end
    render json: @logs
  end

  def log_file
    analysis_log_file = File.join(Rails.root.to_s, 'algorithms','log.txt')
    puts analysis_log_file
    return analysis_log_file
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
