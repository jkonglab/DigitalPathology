class AlgorithmsController < ApplicationController

    before_action :check_admin_user!, :only=> [:new, :edit, :create, :update, :destroy]


    def new
        @algorithm = Algorithm.new
    end

    def edit
        @algorithm = Algorithm.find(params[:id])
        @algorithm[:parameters] = @algorithm.parameters ? @algorithm.parameters.to_json : []
        @algorithm[:multioutput_options] = @algorithm.multioutput_options ? @algorithm.multioutput_options.to_json : ""
    end
    
    def update
        @algorithm = Algorithm.find(params[:id])
        @algorithm.update_attributes(algorithm_params)
        if @algorithm.valid?
            @algorithm.save!
            redirect_to admin_path, notice: "Algorithm edited."
        else
            redirect_to :back
        end
    end

    def destroy
        @algorithm = Algorithm.find(params[:id])
        @algorithm.destroy
        redirect_to admin_path, notice: 'Algorithm is deleted' and return
    end

    def create
        @algorithm = Algorithm.new(algorithm_params)
        if @algorithm.valid?
            if @algorithm.parameters == ""
                @algorithm.parameters = []
            end

            if @algorithm.multioutput_options == ""
                @algorithm.multioutput_options = []
            end

            begin
                !!JSON.parse(@algorithm.parameters.to_s)
            rescue
                flash.now[:alert] = 'Your JSON for parameters is not properly formatted.  Please put your parameters JSON through a linter before resubmitting.'
                render 'users/admin_new_algorithm' and return
            end


            begin
                !!JSON.parse(@algorithm.multioutput_options.to_s)
            rescue
                flash.now[:alert] = 'Your JSON for multioutput parameters is not properly formatted.  Please put your parameters JSON through a linter before resubmitting.'
                render 'users/admin_new_algorithm' and return
            end

            @algorithm.save!
            redirect_to '/admin', notice: "Algorithm created.  Please upload your code folder named #{@algorithm.name} to the algorithms/#{Algorithm::LANGUAGE_LOOKUP_INVERSE[@algorithm.language]} folder on the server."
        else
            redirect_to :back
        end
    end


    def parameter_form
        image = Image.find(params[:image_id])
        @run = image.runs.new
        @algorithm = Algorithm.find(params[:algorithm_id])

        render partial: 'parameter_form'
    end

    private

      def algorithm_params
        params.require(:algorithm).permit(:name, :parameters, :output_type, :input_type, :title, :language, :tile_size, :multioutput, :multioutput_options)
      end

      def check_admin_user!
        if !current_user.admin?
          redirect_to root_path, notice: 'Admins only.'
        end
      end

end