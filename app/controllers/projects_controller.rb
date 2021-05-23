class ProjectsController < InheritedResources::Base

  private

    def project_params
      params.require(:project).permit(:name, :description, :status)
    end
end

