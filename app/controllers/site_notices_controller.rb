class SiteNoticesController < InheritedResources::Base
  before_action :require_admin
  actions :index, :edit, :update, :destroy, :create
  respond_to :js, :only => [:update, :destroy]

  # index

  # edit

  # destroy

  def create
    params = sitenotice_params
    remove_extra_params
    create! do |success, failure|
      success.html {redirect_to(site_notices_path)}
      failure.html
    end
  end

  def update
    params = sitenotice_params
    remove_extra_params
    update! do |success, failure|
      success.html {redirect_to(site_notices_path)}
      failure.html
    end
  end

protected
  def collection
    @collection ||= SiteNotice.send(params[:all] ? :all : :active).paginate(:page => params[:page], :per_page => params[:per_page])
  end
  def sitenotice_params
    params.permit!
  end
  def remove_extra_params
    ['controller','action','task','utf8','_method','authenticity_token','commit'].each{|key| params.delete(key)}
  end
end
