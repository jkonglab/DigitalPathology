class UserProjectOwnershipsController < ApplicationController
  autocomplete :user, :email
  before_action :set_projects_validated, :only =>[:confirm_share, :create]


  def confirm_share
  	@ownership = UserProjectOwnership.new
    query_params = params['q'] || {}
    query_builder = QueryBuilder.new(query_params)
    @q = query_builder.to_ransack(@projects)
    @projects= @q.result.reorder(query_builder.sort_order)
  end

  def create
    user = User.where("lower(email) = ?", params[:user_project_ownership][:user_id].downcase)
    length = @projects.length
    if user.count > 0
      @projects.each do |project|
        UserProjectOwnership.find_or_create_by!(:user_id=>user[0].id, :project_id=>project.id)
      end
      return redirect_to my_projects_path, notice: "#{length} projects shared with #{user[0].email}"
    else
      redirect_to my_projects_path, alert: 'Could not find user to share with'
    end
  end

  private

 def set_projects_validated
    project_ids = params['project_ids']
    if !project_ids
      redirect_to my_projects_path, alert: 'No projects selected'
    else
      @projects = !current_user.subadmin? ? current_user.projects.where('projects.id IN (?)', project_ids) : Project.where('projects.id IN (?)', project_ids)
      if @projects.length < 1
        redirect_to my_project_path, alert: 'No projects selected or you may lack permission to edit these projects'
      end
    end     
  end

end
