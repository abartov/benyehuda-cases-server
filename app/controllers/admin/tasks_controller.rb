class Admin::TasksController < InheritedResources::Base
  before_filter :require_admin, :only => [:create, :update, :changes, :split_task]
  before_filter :require_editor_or_admin, :only => :index
  actions :index, :new, :create, :edit, :update, :destroy, :changes, :split_task
  has_scope :order_by, :only => :index, :using => [:includes, :property, :dir]
  has_scope :order_by_state, :only => :index, :using => [:dir]
  respond_to :js

  def create
    @task = current_user.created_tasks.build(params[:task])
    resource.admin_state = params[:task][:admin_state] || resource.admin_state
    resource.editor_id = params[:task][:editor_id] || resource.editor_id
    resource.assignee_id = params[:task][:assignee_id] || resource.assignee_id
    create! do |success, failure|
      success.html do
        redirect_to (params[:commit] == _("Save and New")) ? new_admin_task_path : task_path(@task)
      end
    end
  end

  def update
    resource.admin_state = params[:task][:admin_state] || resource.admin_state
    resource.editor_id = params[:task][:editor_id] || resource.editor_id
    resource.assignee_id = params[:task][:assignee_id] || resource.assignee_id
    update! do |success, failure|
      success.html {redirect_to task_path(resource)}
    end
  end

  def index
    if "true" == params[:all]
      # reset
      current_user.search_settings.clear!
    elsif (params.keys & Task::SEARCH_KEYS).blank?
      # load defaults
      params.merge!(current_user.search_settings.retrieve)
    end
    current_user.search_settings.set_from_params!(params)
    default_index_with_search!
  end
  def changes
    @raw_changes = Audit.order('updated_at desc').limit(500).paginate(:page => params[:page], :per_page => 100)
    # group audits by task
    @changes = {}
    @ordered_changes = []
    @raw_changes.each {|c|
      unless @changes.has_key? c.task_id
        @changes[c.task_id] = []
        @ordered_changes << c.task_id
      end
      @changes[c.task_id] << c
    }
  end

  def split_task
    @task = Task.find(params[:id])
    if @task.nil?
      flash[:error] = 'אין משימה כזו'
      redirect_to '/'
    else
      @jpegs = @task.documents.select {|x| x.file_file_name =~ /\.(jpg|jpeg|tif|JPG|JPEG|TIF|PNG|png|PDF|pdf)$/}
      if @jpegs.empty?
        flash[:error] = 'אין סריקות במשימה הזו!'
        redirect_to task_path(@task)
      else
        if params[:commit].present? # process filled out form
          Task.transction do
            begin
              @task.lock!('FOR UPDATE NOWAIT')
              @new_tasks = []
              @starter_ids = params.keys.grep(/doc_/) {|x| x[x.index('_')+1..-1].to_i}
              @skip_ids = params.keys.grep(/skip_/) {|x| x[x.index('_')+1..-1].to_i}
              @total_parts = @starter_ids.count
              if @total_parts < 2
                flash[:error] = 'סומנו פחות משתי סריקות; אין טעם לפצל...'
                redirect_to task_path(@task)
              else
                partno = 1
                next_task = prepare_cloned_task(@task, partno, @total_parts)
                docs = []
                @jpegs.each do |jpeg|
                  next if @skip_ids.include?(jpeg.id)
                  if @starter_ids.include?(jpeg.id)
                    unless docs.empty? # if an empty set, this must be the first non-skipped file, so our already-prepared empty task will do
                      @new_tasks << finalize_split_task(next_task, docs, @task.id) # create split task with documents accumulated so far
                      docs = []
                      partno += 1
                      next_task = prepare_cloned_task(@task, partno, @total_parts)
                    end
                  end
                  docs << jpeg
                end
                @new_tasks << finalize_split_task(next_task, docs, @task.id) if docs.count > 0 # finish last split task, if any docs are left
                # prepare new cloned tasks with all metadata copied and ordinal number incremented
                  # iterate through scans until next split marker or end
                    # (if final set equals the document set of the task, report and do nothing)
                  # clone attachments to cloned task
                # change master task type to 'scan' and status to 'עלה לאתר'
                @task.kind_id = TaskKind.where(name: 'סריקה')[0].id
                @task.editor_id = current_user.id
                @task.assignee_id = current_user.id
                @task.state = :ready_to_publish
                @task.save!
                flash[:notice] = 'המשימה פוצלה וסווגה מחדש כמשימת סריקה במצב עלה לאתר!'
                redirect_to task_path(@task)
              end
            rescue
              head :ok # weirdly, split requests that take a while seem to trigger a second request that starts processing in parallel
            end
          end
        end # else render splitting view
      end
    end
  end

  protected
  def collection
    @tasks ||= apply_scopes(Task).filter(params)
  end

  def interpolation_options
    { :task_name => @task.name }
  end
  def prepare_cloned_task(task, partno, total_parts)
    t = task.dup # duplicate attributes from parent task
    pos = t.name.index('/') || 0
    newname = t.name[0..pos-1]+" קבוצה #{partno} מתוך #{total_parts} "
    newname += t.name[pos..-1] unless pos == 0
    t.name = newname.gsub('  ',' ')
    t.documents_count = 0
    t.creator_id = current_user.id
    # t.parent_id = task.id # setting the parent_id before save would trigger Task.clone_parent_documents, which we *don't* want here.
    task.task_properties.each {|tp| t.task_properties << CustomProperty.new(property_id: tp.property_id, custom_value: tp.custom_value)} # copy over custom properties
    t.state = :unassigned
    return t
  end
  def finalize_split_task(task, docs, parent_id)
    task.save! # actually create the task, also triggering the post-create hook!
    # now that the post-create hook has run, we can safely populate the parent id
    task.parent_id = parent_id
    docs.each do |doc|
      d = doc.dup
      d.task_id = task.id
      d.file = Paperclip.io_adapters.for(doc.file)
      d.save
    end
    task.save!
    return task
  end
end
