class PropertiesController < InheritedResources::Base
  before_action :require_admin
  actions :index, :new, :destroy, :create, :update, :edit

  # index
  # new
  # destory
  # edit

  def create
    params = properties_params
    super do |success, failure|
      success.html {redirect_to properties_path}
      failure.html {render :action => "new"}
    end
  end

  def update
    params = properties_params
    super do |success, failure|
      success.html {redirect_to properties_path}
      failure.html {render :action => "edit"}
    end
  end

protected
  def collection
    @properties ||= end_of_association_chain.by_parent_type_and_title.paginate(:page => params[:page], :per_page => params[:per_page])
  end
  def properties_params
    params.require(:property).permit(:title, :parent_type, :property_type, :is_public, :comment)
  end
  
end
