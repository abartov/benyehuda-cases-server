class ReportController < InheritedResources::Base
  before_action :require_editor_or_admin # , :only => [:index, :stalled, :inactive, :active, :newvols, :vols_notify, :do_notify]
  actions :index, :stalled, :active, :inactive, :newvols, :vols_notify, :do_notify, :hours
  before_action :permit_report_params, only: %i[stalled few_tasks_left]
  has_scope :order_by, only: %i[stalled few_tasks_left], using: %i[includes property dir]
  has_scope :order_by_state, only: %i[stalled few_tasks_left], using: [:dir]
  has_scope :order_by_updated_at, only: %i[stalled few_tasks_left], using: [:dir]

  def index
    @current_tab = :reports
  end

  def stalled
    @current_tab = :reports
    base_query = Task.assigned.where(updated_at: 20.years.ago..6.months.ago)
    @tasks = apply_scopes(base_query)
  end

  def hours
    @current_tab = :reports
    @fromdate = params[:fromdate].present? ? Date.parse(params[:fromdate]) : Date.new(Date.today.year, 1, 1) # default to Jan 1st of current year
    @todate = params[:todate].present? ? Date.parse(params[:todate]) : Date.new(Date.today.year, 12, 31) # default to end of current year
    @hours_by_kind = Task.joins(:audits).where(
      "audits.updated_at > ? and audits.updated_at < ? and ((kind_id = 61 and changed_attrs like \"%state:\n-%- ready_to%\") or (changed_attrs like \"%state:\n-%- approved%\"))", @fromdate, @todate
    ).group(:kind_id).sum(:hours)
    @count_by_kind = Task.joins(:audits).where(
      "audits.updated_at > ? and audits.updated_at < ? and ((kind_id = 61 and changed_attrs like \"%state:\n-%- ready_to%\") or (changed_attrs like \"%state:\n-%- approved%\"))", @fromdate, @todate
    ).group(:kind_id).count
    @hours_by_volunteer = Task.joins(:audits).where(
      "audits.updated_at > ? and audits.updated_at < ? and ((kind_id = 61 and changed_attrs like \"%state:\n-%- ready_to%\") or (changed_attrs like \"%state:\n-%- approved%\"))", @fromdate, @todate
    ).group(:assignee_id).sum(:hours)
    @total_hours = @hours_by_kind.values.sum
    @total_tasks = @count_by_kind.values.sum
  end

  def inactive
    @current_tab = :reports
    @total = User.vols_inactive_in_last_n_months(6).count
    @users = User.vols_inactive_in_last_n_months(6).paginate(page: params[:page], per_page: params[:per_page])
  end

  def active
    @current_tab = :reports
    users = User.vols_active_in_last_n_months(6)
    @total = users.count
    @emails = users.pluck(:email).join(', ')
    @users = users.paginate(page: params[:page], per_page: params[:per_page])
  end

  def few_tasks_left
    @current_tab = :reports
    # For TaskKind 1, group by parent_id
    # For TaskKind 21, group by grandparent (parent's parent_id)

    # Get available kinds for the dropdown filter
    @available_kinds = TaskKind.where(id: [1, 21]).order(:name)

    # Determine which kinds to query based on filter
    kind_ids = params[:kind_id].present? ? [params[:kind_id].to_i] : [1, 21]

    # First, find parent/grandparent IDs that have fewer than 3 tasks
    parent_group_sql = "CASE WHEN tasks.kind_id = 21 THEN parent_tasks.parent_id ELSE tasks.parent_id END"
    few_tasks_parents = Task.joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
                            .where(kind_id: kind_ids, state: 'unassigned')
                            .group(parent_group_sql)
                            .having('count(tasks.id) < 3')
                            .pluck(Arel.sql(parent_group_sql))
                            .compact

    @total = few_tasks_parents.count

    # Now fetch all tasks that belong to those parents, with sorting
    if few_tasks_parents.any?
      base_query = Task.joins("LEFT JOIN tasks AS parent_tasks ON tasks.parent_id = parent_tasks.id")
                       .joins(:kind)
                       .includes(:parent, :kind, :documents)
                       .where(kind_id: kind_ids, state: 'unassigned')
                       .where("#{parent_group_sql} IN (?)", few_tasks_parents)
                       .order('task_kinds.name', 'tasks.created_at')
      @tasks = apply_scopes(base_query).paginate(page: params[:page], per_page: params[:per_page])
    else
      @tasks = Task.none.paginate(page: params[:page], per_page: params[:per_page])
    end
  end

  def missing_metadata
    @current_tab = :reports
    typing = TaskKind.where(name: 'הקלדה')[0].id
    proofing = TaskKind.where(name: 'הגהה')[0].id
    filters = []
    filters << ' include_images is null ' unless params[:images].present?
    filters << ' independent is null ' unless params[:independent].present?
    filters << ' genre is null ' unless params[:genre].present?
    filters << ' task_teams.task_id is null ' unless params[:team].present?
    filters = filters.join(' OR ')
    condition = "state <> 'ready_to_publish' AND (kind_id = #{typing} OR kind_id = #{proofing})"
    condition = "name like '%#{params[:q]}%' AND #{condition}" if params[:q].present?
    condition += " AND (#{filters})" if filters.present?
    @tasks = if params[:team].present?
               Task.where(condition).paginate(page: params[:page], per_page: params[:per_page])
             else
               # joins team_memberships to return tasks that aren't associated with a team
               Task.joins('LEFT JOIN task_teams ON tasks.id = task_teams.task_id').where("#{condition}").paginate(
                 page: params[:page], per_page: params[:per_page]
               )
             end
  end

  def missing_metadata_panel
    @task = Task.find(params[:id])
    if @task
      @possibly_related = @task.possibly_related_tasks
      render layout: false
    else
      head :ok
    end
  end

  def update_metadata
    @task = Task.find(params[:task_id])
    if @task
      tasks_to_update = [@task]
      params.keys.each { |p| tasks_to_update << Task.find(p[4..-1]) if p =~ /task\d+/ }
      indep = params[:independent].nil? ? false : true
      images = params[:include_images].nil? ? false : true
      team = params[:team_id].present? ? Team.find(params[:team_id]) : nil
      tasks_to_update.each do |t|
        t.genre = params[:genre]
        t.independent = indep
        t.include_images = images
        t.teams << team if team.present?
        t.save!
      end
      render js: "$('.metadata_dialog').dialog('close');"
    else
      head :ok
    end
  end

  def newvols
    @current_tab = :reports
    @fromdate = params[:fromdate].present? ? Date.parse(params[:fromdate]) : Date.new(Date.today.year, 1, 1) # default to Jan 1st of current year
    @todate = params[:todate].present? ? Date.parse(params[:todate]) : Date.new(Date.today.year, 12, 31) # default to end of current year
    @users = User.vols_created_between(@fromdate, @todate)
    return unless params[:download_csv] == '1'

    csv_buffer = ['שם משתמש,דואל,תאריך הפעלה,מזהה']
    @users.each { |u| csv_buffer << "#{u.name},#{u.email},#{u.activated_at},#{u.id}" }
    csv_buffer = csv_buffer.join("\n")
    send_data csv_buffer, filename: "new_volunteers_#{@fromdate}_to_#{@todate}.csv"
  end

  def vols_notify
    @current_tab = :reports
    newly_published_tasks = Task.ready_to_publish.where(updated_at: 1.month.ago..Date.today)
    @users = []
    newly_published_tasks.each do |t|
      @users << t.assignee unless @users.include?(t.assignee)
    end
    emails = @users.map { |u| u.email }
    @emails = emails.join(', ')
    session['vols_to_notify'] = @users
  end

  def do_notify
    # do notify
    users = session['vols_to_notify']
    if users.nil? or users.empty?
      flash[:error] = _('No volunteers to notify')
    else
      users.each { |u| Notification.tasks_added_to_site(u).deliver }
      flash[:notice] = _('E-mails sent to volunteers')
    end
    redirect_to report_path
  end

  private

  def permit_report_params
    @permitted_report_params = params.permit(:page, :per_page, :dir, :includes, :property,
                                             :order_by, :order_by_state, :order_by_updated_at, :q, :kind_id)
  end
end
