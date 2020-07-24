class ReportController < InheritedResources::Base
  before_filter :require_editor_or_admin #, :only => [:index, :stalled, :inactive, :active, :newvols, :vols_notify, :do_notify]
  actions :index, :stalled, :active, :inactive, :newvols, :vols_notify, :do_notify, :hours

  def index
  end
  def stalled
    @tasks = Task.assigned.where(:updated_at => 20.years.ago..6.months.ago)
  end

  def hours
    @fromdate = params[:fromdate].present? ? Date.parse(params[:fromdate]) : Date.new(Date.today.year, 1, 1) # default to Jan 1st of current year
    @todate = params[:todate].present? ? Date.parse(params[:todate]) : Date.new(Date.today.year, 12,31) # default to end of current year
    @hours_by_kind = Task.where("state in ('ready_to_publish', 'approved', 'other_task_creat') and updated_at > ? and updated_at < ?", @fromdate, @todate).group(:kind_id).sum(:hours)
    @count_by_kind = Task.where("state in ('ready_to_publish', 'approved', 'other_task_creat') and updated_at > ? and updated_at < ?", @fromdate, @todate).group(:kind_id).count
    @total_hours = @hours_by_kind.values.sum
    @total_tasks = @count_by_kind.values.sum
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
