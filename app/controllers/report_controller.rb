class ReportController < InheritedResources::Base
  before_filter :require_editor_or_admin #, :only => [:index, :stalled, :inactive, :active, :newvols, :vols_notify, :do_notify]
  actions :index, :stalled, :active, :inactive, :newvols, :vols_notify, :do_notify, :hours

  def index
  end
  def stalled
    @tasks = Task.assigned.where(:updated_at => 20.years.ago..6.months.ago)
  end

  def hours
    @year = Date.today.year-1
    @completed_tasks = Task.where('state = "ready_to_publish" and updated_at > ? and updated_at < ?', Date.new(@year, 1,1), Date.new(Date.today.year,1,1))
    @hours_total = @completed_tasks.pluck(:hours).reject{|x| x.nil?}.sum
  end

  def inactive
    @total = User.vols_inactive_in_last_n_months(6).count
    @users = User.vols_inactive_in_last_n_months(6).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def active
    @total = User.vols_active_in_last_n_months(6).count
    @users = User.vols_active_in_last_n_months(6).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def newvols
    @users = User.vols_newer_than(4.months.ago).paginate(:page => params[:page], :per_page => params[:per_page])
  end
  def vols_notify
    newly_published_tasks = Task.ready_to_publish.where(:updated_at => 1.month.ago..Date.today)
    @users = []
    newly_published_tasks.each {|t|
      @users << t.assignee unless @users.include?(t.assignee)
    }
    emails = @users.map {|u| u.email}
    @emails = emails.join(', ')
    session["vols_to_notify"] = @users
  end
  def do_notify
    # do notify
    users = session["vols_to_notify"]
    unless users.nil? or users.empty?
      users.each {|u| Notification.tasks_added_to_site(u).deliver }
      flash[:notice] = _("E-mails sent to volunteers")
    else
      flash[:error] = _("No volunteers to notify")
    end
    redirect_to report_path
  end
end
