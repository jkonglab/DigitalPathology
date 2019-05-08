class ProjectsController < ApplicationController
  include ApplicationHelper
  before_action :set_current_user
  before_action :authenticate_user!, :except => [:index]
  before_action :set_project_validated, :except => [:index, :my_projects, :new, :create, :make_private, :make_public, :share]
  before_action :set_projects_validated, :only => [:make_private, :make_public, :share]

  def index
  end

  def my_projects
	  query_params = params['q'] || {}
	  query_builder = QueryBuilder.new(query_params)
	  @q = query_builder.to_ransack(current_user.projects)
	  @projects= @q.result.reorder(query_builder.sort_order)
	end

	def rerun
    all_reruns = Image.where(:complete=>false, :project_id=>@project.id)
    all_reruns.each do |image|
      Sidekiq::Client.push('queue' => 'user_conversion_queue_' + current_user.id.to_s, 'class' =>  ConversionWorker, 'args' => [image.id])
    end
    redirect_back(fallback_location: project_path(@project))
  end

	def show
	  query_params = params['q'] || {}
	  query_builder = QueryBuilder.new(query_params)
	  @q = query_builder.to_ransack(@project.images.where(:project_id=>params[:id], :parent_id => nil))
	  @images= @q.result.reorder(query_builder.sort_order)
	end

	def new
		@project = Project.new
	end

	def edit
	end

	def update
		@project.update_attributes(project_params)
		if @project.valid?
			@project.save!
			redirect_to my_projects_path, notice: "Project edited."
		else
			redirect_to :back
		end
	end

	def create
		@project = Project.new(project_params)
		if @project.valid?
			@project.save!
			UserProjectOwnership.create!(:project_id=>@project.id, :user_id=>current_user.id)
			redirect_to my_projects_path, notice: "Project created."
		else
			redirect_back(fallback_location: my_projects_path)
		end
	end

	def make_public
		@projects.update_all(:visibility=> :visible)
		redirect_back(fallback_location: my_projects_path, notice: "#{@projects.length} project(s) made public")
	end

	def make_private
		@projects.update_all(:visibility=> :hidden)
		redirect_back(fallback_location: my_projects_path, notice: "#{@projects.length} project(s) made private")
	end

	def destroy
		if @project.images.length == 0
			@project.destroy
			redirect_to my_projects_path, notice: 'Empty project is deleted' and return
		else
			redirect_to my_projects_path, alert: 'You cannot delete a non-empty project.  Please delete the images inside before deleting the project.' and return
		end
	end

	private
	  def project_params
	    params.require(:project).permit(:title, :modality, :tissue_type, :method, :visibility, :description)
	  end

	  def set_project_validated
	    @project = Project.find(params[:id])

	    if @project.hidden? && !(@project.users.pluck(:id).include?(current_user.id)) && !current_user.subadmin?
	      redirect_to my_projects_path, alert: 'You do not have permission to access or edit this project'
	    end
	  end

		def set_projects_validated
	  	project_ids = params['project_ids']
	    if !project_ids
	      redirect_back(fallback_location: my_projects_path, alert: 'No projects selected')
	    else
	      user_project_ids = current_user.projects.pluck(:id)
	      @projects = !current_user.subadmin? ? Project.where('projects.id IN (?) AND projects.id IN (?)', project_ids, user_project_ids) : Project.where('projects.id IN (?)', project_ids)
	      if @projects.length < 1
	        redirect_back(fallback_location: my_projects_path, alert: 'No projects selected or you may lack permission to edit these projects')
	      end
	    end 
  	end

end
