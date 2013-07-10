class ReportController < InheritedResources::Base
  before_filter :require_editor_or_admin #, :only => [:index, :stalled, :inactive, :active, :newvols]
  actions :index, :stalled, :active, :inactive, :newvols



  def index
  end
  def stalled
  end

  def inactive
    @users = User.vols_inactive_in_last_n_months(6).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def active
    @users = User.vols_active_in_last_n_months(6).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def newvols
    @users = User.vols_newer_than(4.months.ago).paginate(:page => params[:page], :per_page => params[:per_page])
  end
end
