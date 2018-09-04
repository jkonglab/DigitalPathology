class UserRunOwnershipsController < ApplicationController
  autocomplete :user, :email
  before_action :set_runs_validated, :only =>[:confirm_share, :create]


  def confirm_share
  	@ownership = UserRunOwnership.new
  end

  def create
    user = User.where("lower(email) = ?", params[:user_run_ownership][:user_id].downcase)
    length = @runs.length
    if user.count > 0
      @runs.each do |run|
        UserRunOwnership.find_or_create_by!(:user_id=>user[0].id, :run_id=>run.id)
      end
      return redirect_to runs_path, notice: "#{length} analyses shared with #{user[0].email}"
    else
      redirect_to runs_path, alert: 'Could not find user to share with'
    end
  end

  private

  def set_runs_validated
    run_ids = params['run_ids']
    if !run_ids
      redirect_to runs_path, alert: 'No analyses selected.'
    else
      @runs = current_user.runs.where('runs.id IN (?)', run_ids)
      if @runs.length < 1
        redirect_to runs_path, alert: 'No analyses selected or you may lack permission to edit these analyses'
      end
    end     
  end

end
