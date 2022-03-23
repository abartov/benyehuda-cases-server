class ReportController < InheritedResources::Base
  before_action :require_editor_or_admin #, :only => [:index, :stalled, :inactive, :active, :newvols, :vols_notify, :do_notify]
  actions :index, :stalled, :active, :inactive, :newvols, :vols_notify, :do_notify, :hours

  def index
    @current_tab = :reports
  end
  def stalled
    @current_tab = :reports
    @tasks = Task.assigned.where(:updated_at => 20.years.ago..6.months.ago)
  end

  def hours
    @current_tab = :reports
    @fromdate = params[:fromdate].present? ? Date.parse(params[:fromdate]) : Date.new(Date.today.year, 1, 1) # default to Jan 1st of current year
    @todate = params[:todate].present? ? Date.parse(params[:todate]) : Date.new(Date.today.year, 12,31) # default to end of current year
    @hours_by_kind = Task.joins(:audits).where("audits.updated_at > ? and audits.updated_at < ? and ((kind_id = 61 and changed_attrs like \"%state:\n-%- ready_to%\") or (changed_attrs like \"%state:\n-%- approved%\"))", @fromdate, @todate).group(:kind_id).sum(:hours)
    @count_by_kind = Task.joins(:audits).where("audits.updated_at > ? and audits.updated_at < ? and ((kind_id = 61 and changed_attrs like \"%state:\n-%- ready_to%\") or (changed_attrs like \"%state:\n-%- approved%\"))", @fromdate, @todate).group(:kind_id).count
    @hours_by_volunteer = Task.joins(:audits).where("audits.updated_at > ? and audits.updated_at < ? and ((kind_id = 61 and changed_attrs like \"%state:\n-%- ready_to%\") or (changed_attrs like \"%state:\n-%- approved%\"))", @fromdate, @todate).group(:assignee_id).sum(:hours)
    @total_hours = @hours_by_kind.values.sum
    @total_tasks = @count_by_kind.values.sum
  end

  def inactive
    @current_tab = :reports
    @total = User.vols_inactive_in_last_n_months(6).count
    @users = User.vols_inactive_in_last_n_months(6).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def active
    @current_tab = :reports
    users = User.vols_active_in_last_n_months(6)
    @total = users.count
    @emails = users.pluck(:email).join(', ')
    @users = users.paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def missing_metadata
    @current_tab = :reports
    typing = TaskKind.where(name: 'הקלדה')[0].id
    proofing = TaskKind.where(name: 'הגהה')[0].id
    @tasks = Task.where("state <> 'ready_to_publish' AND (include_images is null or independent is null or genre is null) AND (kind_id = #{typing} OR kind_id = #{proofing})").paginate(:page => params[:page], :per_page => params[:per_page])
  end
  def missing_metadata_panel
    @task = Task.find(params[:id])
    unless @task
      head :ok
    else
      @possibly_related = @task.possibly_related_tasks
      render :layout => false
    end
  end
  def update_metadata
    @task = Task.find(params[:task_id])
    unless @task
      head :ok
    else
      tasks_to_update = [@task]
      params.keys.each{|p| tasks_to_update << Task.find(p[4..-1]) if p =~ /task\d+/}
      indep = params[:independent].nil? ? false : true
      images = params[:include_images].nil? ? false : true
      tasks_to_update.each do |t|
        t.genre = params[:genre]
        t.independent = indep
        t.include_images = images
        t.save!
      end
      render :js => "$('.metadata_dialog').dialog('close');"
    end
  end
  def newvols
    @current_tab = :reports
    @fromdate = params[:fromdate].present? ? Date.parse(params[:fromdate]) : Date.new(Date.today.year, 1, 1) # default to Jan 1st of current year
    @todate = params[:todate].present? ? Date.parse(params[:todate]) : Date.new(Date.today.year, 12,31) # default to end of current year
    @users = User.vols_created_between(@fromdate, @todate)
    if params[:download_csv] == '1'
      csv_buffer = ['שם משתמש,דואל,תאריך הפעלה,מזהה']
      @users.each{|u| csv_buffer << "#{u.name},#{u.email},#{u.activated_at},#{u.id}" }
      csv_buffer = csv_buffer.join("\n")
      send_data csv_buffer, filename: "new_volunteers_#{@fromdate.to_s}_to_#{@todate.to_s}.csv"
    end
  end
  def vols_notify
    @current_tab = :reports
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
