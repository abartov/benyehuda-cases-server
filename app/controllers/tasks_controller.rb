require 'httparty'

class TasksController < InheritedResources::Base
  before_action :require_task_participant_or_editor, only: %i[show update edit download_pdf]
  before_action :require_editor_or_admin, only: %i[index create make_comments_editor_only get_last_source]
  actions :index, :show, :update, :create
  autocomplete :task, :name, full: true, extra_data: [:kind_id], display_value: :name_with_kind
  has_scope :order_by, :only => :index, :using => [:includes, :property, :dir]
  has_scope :order_by_state, :only => :index, :using => [:dir]

  EVENTS_WITH_COMMENTS = { 'reject' => N_('Task rejected'), 'abandon' => N_('Task abandoned'),
                           'finish' => N_('Task completed'), 'help_required' => N_('Help required') }

  # this action is called when a volunteer clicks "finish" on a task.
  def edit
    return unless _allow_event?(resource, :finish, current_user)

    @no_docs_uploaded = resource.documents.uploaded_by(current_user).count.zero?
    resource.hours = resource.estimate_hours unless resource.hours.present?
  end

  def download_pdf
    @task = Task.find(params[:id])
    if @task
      tmpfile = Tempfile.new(['dl_task_pdf__', '.pdf'])
      begin
        jpegs = @task.documents.select { |x| x.file_file_name =~ /\.(jpg|jpeg|tif|JPG|JPEG|TIF|PNG|png|PDF|pdf)$/ }
        if params['dtype'].blank? || params['dtype'] == 'maintext'
          jpegs = jpegs.select { |x| x.document_type == 'maintext' }
        elsif params['dtype'] == 'front'
          jpegs = jpegs.select { |x| x.document_type == 'front' }
        elsif params['dtype'] == 'footnotes'
          jpegs = jpegs.select { |x| x.document_type == 'footnotes_and_corrigenda' }
        else
          flash[:error] = 'התבקש סוג הורדה לא תקין'
          redirect_to task_path(@task)
          return
        end
        if jpegs.empty?
          flash[:error] = 'אין סריקות מתאימות להורדה!'
          redirect_to task_path(@task)
          return
        end
        tmpjpegs = []
        jpegs.each do |jpeg|
          jpegext = jpeg.file_file_name[jpeg.file_file_name.rindex('.')..-1]
          tmpjpeg = Tempfile.new(['dl_task_jpg__', jpegext], binmode: true)
          tmpjpegpath = tmpjpeg.path
          tmpjpegs << tmpjpeg
          response = HTTParty.get(jpeg.file.url)
          tmpjpeg.write(response.body)
          tmpjpeg.flush
        end
        tmpfilename = tmpfile.path
        inputfiles = tmpfilename + '_input.txt'
        # img2pdf needs NUL-separated list
        File.open(inputfiles, 'w') do |f|
          f.write(tmpjpegs.map do |tj|
                    tj.path
                  end.join("\0"))
        end
        # run the conversion
        # for this to work, ImageMagick must not restrict PDFs! See here: https://stackoverflow.com/questions/52998331/imagemagick-security-policy-pdf-blocking-conversion
        # `convert @#{inputfiles} #{tmpfilename}`
        # ImageMagick was producing low-quality PDFs, so switched to img2pdf:
        `img2pdf --from-file #{inputfiles} -o #{tmpfilename}`
        pdf = File.read(tmpfilename)
        send_data pdf, type: 'application/pdf', filename: "Task_#{@task.id}.pdf"
        File.delete(tmpfilename) # delete temporary generated PDF
        File.delete(inputfiles)
      rescue StandardError
        redirect_to '/'
      ensure
        tmpfile.close
      end
    else
      redirect_to '/'
    end
  end

  def get_last_source
    @task = Task.last
    respond_to do |format|
      format.js
    end
  end

  def make_comments_editor_only
    @task = Task.find(params[:id])
    @task.comments.each do |c|
      c.editor_eyes_only = true
      c.save!
    end
    redirect_to(@task)
  end

  def create
    params = task_params
    @task = Task.find(params[:id])

    return unless _allow_event?(@task, :create_other_task, current_user)

    @chained_task = @task.build_chained_task(params[:task], current_user)
    @comment = @chained_task.comments.first
    if @chained_task.save
      flash[:notice] = _('Task created.')
      redirect_to task_path(@chained_task)
    else
      puts "DBG: #{@chained_task.errors.full_messages}"
      flash[:error] = @chained_task.errors.full_messages
      redirect_to task_path(@task)
    end
  end

  def index
    # @tasks = Task.unassigned.paginate(:page => params[:page], :per_page => params[:per_page])
    # if params[:kind].nil? or params[:kind].blank?
    #  tasks = Task.unassigned.sort_by {|t|
    #    kindname = t.kind.nil? ? '' : t.kind.try(:name) # shouldn't happen -- is only the case in some odd old test items
    #    kindname + t.updated_at.to_i.to_s # manual sort :( # TODO: figure out how to do this through the assoc
    #  }
    #  @tasks = tasks.reverse.paginate(:page => params[:page], :per_page => params[:per_page])
    # else
    # params[:state] = :unassigned
    # current_user.search_settings.set_from_params!(params)
    conds = {}
    joins = []
    conds[:kind_id] = TaskKind.find_by_name(params[:kind]).id if params[:kind].present?
    conds[:full_nikkud] = params[:full_nikkud] == 'true' if params[:full_nikkud].present?
    conds[:genre] = params[:genre] if params[:genre].present?
    if params[:team].present?
      conds[:teams] = { id: params[:team] }
      joins << :teams
    end
    
    # Build base query with filters
    base_query = Task.unassigned.joins(joins).where(conds)
    
    # Apply sorting scopes if present
    @tasks = if params[:order_by].present? || params[:order_by_state].present? || params[:sort_by].present?
               apply_scopes(base_query)
             else
               base_query.order('updated_at desc')
             end
    
    # Handle percent_done sorting (special case like in DashboardsController)
    if params[:sort_by] == 'percent_done'
      @tasks = @tasks.to_a.sort { |a, b| a.percent_done <=> b.percent_done }
      @tasks.reverse! if params[:dir] == 'DESC'
    end
    
    @tasks = @tasks.paginate(page: params[:page], per_page: params[:per_page])
    # end

    @assignee = User.find(params[:assignee_id]) if params[:assignee_id]
  end

  def show
    @task = Task.eager_load(documents: :user).find(params[:id])
    @comments = @task.comments.with_user.send(current_user.admin_or_editor? ? :all : :public_comments)
    show!
  end

  def update
    return unless _allow_event?(resource, params[:event], current_user)

    params = task_params

    # all security verifications passed in allow_event_for?
    return _event_with_comment(params[:event]) if resource.commentable_event?(params[:event])

    resource.send(params[:event])
    resource.save

    flash[:notice] = _('Task updated')

    redirect_to task_path(resource)
  end

  protected

  def require_task_participant_or_editor
    return false unless require_user
    return true if current_user.admin_or_editor?
    return true if resource.participant?(current_user) # participant

    flash[:error] = _('Only participant can see this page')
    redirect_to '/'
    false
  end

  def _event_with_comment(event)
    resource.hours = params[:task][:hours].to_i if params[:task][:hours].present?

    unless resource.event_with_comment(event, params[:task])
      respond_to do |format|
        format.html
        format.js { render partial: 'event_with_comment', locals: { event: event } }
      end
      return
    end

    resource.save
    flash[:notice] = s_(resource.class.event_complete_message(event))
    respond_to do |format|
      format.html
      format.js do
        render partial: 'event_with_comment_redir',
               locals: { to: resource.participant?(current_user) ? task_path(resource) : dashboard_path }
      end
    end
  end

  def _allow_event?(task, event, user)
    return true if task.allow_event_for?(event, user)

    flash[:error] = _("Sorry, you're not allowed to perfrom this operation")

    respond_to do |wants|
      wants.html { redirect_to task_path(task) }
      wants.js do
        render partial: 'redir_task', locals: { task: task }
      end
    end

    false
  end

  def task_params
    params.permit!
  end
end
