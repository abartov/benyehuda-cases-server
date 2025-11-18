class Admin::TasksController < InheritedResources::Base
  include ActionController::Cookies # include ActionController
  before_action :load_authlogic
  before_action :require_admin, only: %i[create update changes split_task start_ingestion]
  before_action :require_editor_or_admin, only: %i[index new create split_task]
  actions :index, :new, :create, :edit, :update, :destroy, :changes, :split_task, :start_ingestion
  has_scope :order_by, only: :index, using: %i[includes property dir]
  has_scope :order_by_state, only: :index, using: [:dir]
  respond_to :js

  def new
    remove_extra_params
    super
  end

  def create
    params = task_params
    @task = current_user.created_tasks.build(params[:task])
    resource.admin_state = params[:task][:admin_state] || resource.admin_state
    resource.editor_id = params[:task][:editor_id] || resource.editor_id
    resource.assignee_id = params[:task][:assignee_id] || resource.assignee_id
    remove_extra_params
    create! do |success, failure|
      success.html do
        redirect_to params[:commit] == _('Save and New') ? new_admin_task_path : task_path(@task)
      end
    end
  end

  def update
    params = task_params
    resource.admin_state = params[:task][:admin_state] || resource.admin_state
    resource.editor_id = params[:task][:editor_id] || resource.editor_id
    resource.assignee_id = params[:task][:assignee_id] || resource.assignee_id
    remove_extra_params
    update! do |success, failure|
      success.html { redirect_to task_path(resource) }
    end
  end

  def index
    if 'true' == params[:all]
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
    @raw_changes = Audit.order('updated_at desc').limit(500).paginate(page: params[:page], per_page: 100)
    # group audits by task
    @changes = {}
    @ordered_changes = []
    @raw_changes.each do |c|
      unless @changes.has_key? c.task_id
        @changes[c.task_id] = []
        @ordered_changes << c.task_id
      end
      @changes[c.task_id] << c
    end
  end

  def classify_scans
    @task = Task.find(params[:id])
    if @task.nil?
      flash[:error] = 'אין משימה כזו'
      redirect_to '/'
    else
      @jpegs = @task.documents.select { |x| x.file_file_name =~ /\.(jpg|jpeg|tif|JPG|JPEG|TIF|PNG|png)$/ }
      if @jpegs.empty?
        flash[:error] = 'אין סריקות במשימה הזו!'
        redirect_to task_path(@task)
      elsif params[:commit].present?
        @starter_ids = params.keys.grep(/front_/) { |x| x[x.index('_') + 1..].to_i }
        @footnote_ids = params.keys.grep(/footnotes_/) { |x| x[x.index('_') + 1..].to_i }
        @jpegs.each do |jpeg|
          if @starter_ids.include?(jpeg.id)
            jpeg.document_type = 'front'
          elsif @footnote_ids.include?(jpeg.id)
            jpeg.document_type = 'footnotes_and_corrigenda'
          else
            # should already be the default, but conceivably a task could be *re-classified* to correct a mistake
            jpeg.document_type = 'maintext'
          end
          jpeg.save!
        end
        redirect_to task_path(@task)
      end
    end
  end

  def split_task
    @task = Task.find(params[:id])
    if @task.nil?
      flash[:error] = 'אין משימה כזו'
      redirect_to '/'
    else
      # select front matter and footnotes
      @fronts = @task.documents.select { |x| x.document_type == 'front' }
      @footnotes = @task.documents.select { |x| x.document_type == 'footnotes_and_corrigenda' }
      @jpegs = @task.documents.select do |x|
        x.document_type == 'maintext' && x.file_file_name =~ /\.(jpg|jpeg|tif|JPG|JPEG|TIF|PNG|png|PDF|pdf)$/
      end
      if @jpegs.empty?
        flash[:error] = 'אין סריקות במשימה הזו!'
        redirect_to task_path(@task)
      elsif params[:commit].present?
        if @task.priority == 'being_split'
          head :ok # weirdly, split requests that take a while seem to trigger a second request that starts processing in parallel
        else
          old_priority = @task.priority
          @task.priority = 'being_split' # hacky lock because pessimistic locking didn't work for me on the Amazon RDS server
          @task.save!
          @new_tasks = []
          @starter_ids = params.keys.grep(/doc_/) { |x| x[x.index('_') + 1..-1].to_i }
          @skip_ids = params.keys.grep(/skip_/) { |x| x[x.index('_') + 1..-1].to_i }
          @total_parts = @starter_ids.count
          if @total_parts < 2
            flash[:error] = 'סומנו פחות משתי סריקות; אין טעם לפצל...'
          else
            partno = 1
            next_task = prepare_cloned_task(@task, partno, @total_parts)
            docs = []
            @jpegs.each do |jpeg|
              next if @skip_ids.include?(jpeg.id)

              if @starter_ids.include?(jpeg.id) && !docs.empty? # if an empty set, this must be the first non-skipped file, so our already-prepared empty task will do
                @new_tasks << finalize_split_task(next_task, docs, @task.id, @fronts.dup, @footnotes.dup) # create split task with documents accumulated so far
                docs = []
                partno += 1
                next_task = prepare_cloned_task(@task, partno, @total_parts)
              end
              docs << jpeg
            end
            # finish last split task, if any docs are left
            @new_tasks << finalize_split_task(next_task, docs, @task.id, @fronts.dup, @footnotes.dup) if docs.count > 0
            # prepare new cloned tasks with all metadata copied and ordinal number incremented
            # iterate through scans until next split marker or end
            # (if final set equals the document set of the task, report and do nothing)
            # clone attachments to cloned task
            # change master task type to 'scan' and status to 'עלה לאתר'
            @task.kind_id = TaskKind.where(name: 'סריקה')[0].id
            @task.editor_id = current_user.id
            @task.assignee_id = current_user.id
            @task.state = :ready_to_publish
            @task.priority = old_priority
            @task.save!
            flash[:notice] = 'המשימה פוצלה וסווגה מחדש כמשימת סריקה במצב עלה לאתר!'
          end
          redirect_to task_path(@task)
        end
      end
    end
  end

  # prepare JSON payload for user's browser to POST to benyehuda.org
  def start_ingestion
    @task = Task.find(params[:id])
    @title = @task.name
    @genre = @task.genre
    @credits = @task.gather_all_involved.join('; ')
    @orig_lang = @task.orig_lang
    @publisher = @task.source
    docx = []
    @task.documents.each do |doc|
      next unless doc.document_type == 'maintext'

      url = doc.file.url
      url = url[0..url.index('?') - 1] if url.index('?')
      docx << doc if url.ends_with?('.docx')
    end
    @docx = docx.present? ? docx.last.file.url : nil
  end

  protected

  def collection
    @tasks ||= apply_scopes(Task).filter(params)
  end

  def interpolation_options
    { task_name: @task.name }
  end

  def prepare_cloned_task(task, partno, total_parts)
    t = task.dup # duplicate attributes from parent task
    pos = t.name.index('/') || 0
    newname = t.name[0..pos - 1] + " – קבוצה #{partno} מתוך #{total_parts} "
    newname += t.name[pos..-1] unless pos == 0
    t.name = newname.gsub('  ', ' ')
    t.documents_count = 0
    t.priority = ''
    t.creator_id = current_user.id
    # t.parent_id = task.id # setting the parent_id before save would trigger Task.clone_parent_documents, which we *don't* want here.
    # copy over custom properties
    task.task_properties.each do |tp|
      t.task_properties << CustomProperty.new(property_id: tp.property_id, custom_value: tp.custom_value)
    end
    t.state = :unassigned
    task.teams.each { |team| t.teams << team } # copy over team assignments
    t
  end

  def finalize_split_task(task, docs, parent_id, fronts, footnotes)
    task.save! # actually create the task, also triggering the post-create hook!
    # now that the post-create hook has run, we can safely populate the parent id
    task.parent_id = parent_id
    # copy over front matter, footnotes and corrigenda
    [fronts, footnotes, docs].each do |list|
      next unless list.present?

      list.each do |doc|
        d = Document.create(task_id: task.id, user_id: doc.user_id, document_type: doc.document_type)
        d.file = doc.file.url
        d.save!
      end
    end
    task.save!
    task
  end

  def task_params
    params.permit!
  end

  def remove_extra_params
    params[:task].each { |k, v| params[k] = v } if params[:task].present?
    %w[controller action task utf8 _method authenticity_token commit].each { |key| params.delete(key) }
  end

  def load_authlogic
    return unless Authlogic::Session::Base.controller.nil?

    Authlogic::Session::Base.controller = Authlogic::ControllerAdapters::RailsAdapter.new(self)
  end
end
