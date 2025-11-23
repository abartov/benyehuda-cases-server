# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# BEWARE! currently implicitly seeded for i18n'ed task ordering through db/seeds.rb
#
module States

  def self.included(base)
    base.class_eval do
      include AASM
      aasm.attribute_name('state')
      validates :state, :presence => true
      validates :assignee, :editor, :presence => true, :if => :should_have_assigned_peers?, :on => :update

      aasm column: :state do
        # somebody has to start working on it
        state          :unassigned

        # assigned to assignee and edtior
        state          :assigned

        # assignee is stuck and need editor's help
        state          :stuck # needs some fixups such as words in foreign alphabet or missing scans

        # assignee work in progress, and partially ready
        # NOTE: As of Nov 2012, this state is not used.
        state          :partial

        # assignee complete the work
        state          :waits_for_editor

        # editor rejects the task, assignee should fix whatever is done wrong
        state          :rejected

        # editor confirms that task is completed by assignee
        state          :approved

        # editor marks for technical editing
        state          :techedit

        # editor confirms that task is ready to be published
        state          :ready_to_publish

        # editor confirms that a child task created (proofing or other task)
        state          :other_task_creat

      end
        # assign a task to new assignee
        aasm.event :_assign do
          transitions :from => [:unassigned, :assigned], :to => :assigned
          transitions :from => :waits_for_editor, :to => :waits_for_editor
          transitions :from => :confirmed, :to => :confirmed
          transitions :from => :other_task_creat, :to => :other_task_creat
          transitions :from => :approved, :to => :approved
          transitions :from => :approved, :to => :techedit
          transitions :from => :ready_to_publish, :to => :ready_to_publish
          transitions :from => :stuck, :to => :stuck
          transitions :from => :partial, :to => :partial
          transitions :from => :rejected, :to => :rejected
        end
      protected :_assign, :_assign!

        # reject assignment
        aasm.event :_abandon do
          transitions :from => [:assigned, :stuck, :partial, :rejected, :confirmed], :to => :unassigned
        end
        protected :_abandon, :_abandon!

        # assignee needs editor's help
        aasm.event :_help_required do
          transitions :from => [:assigned, :partial, :rejected, :waits_for_editor], :to => :stuck
        end

        # assignee finished partially her work
        aasm.event :finish_partially do
          transitions :from => [:assigned, :stuck, :partial, :rejected], :to => :partial
        end

        # assignee finished the work
        aasm.event :finish do
          transitions :from => [:assigned, :stuck, :partial, :rejected, :stuck], :to => :waits_for_editor
        end

        # editor approves the work
        aasm.event :approve do
          transitions :from => :waits_for_editor, :to => :approved
        end

        # editor marks for technical editing
        aasm.event :to_techedit do
          transitions from: :approved, to: :techedit
        end

        # editor rejects the work
        aasm.event :_reject do
          transitions :from => :waits_for_editor, :to => :rejected
        end
        protected :_reject, :_reject!

        # edtior, admin marks as ready to publish
        aasm.event :complete do
          transitions :from => [:approved, :other_task_creat, :techedit], :to => :ready_to_publish
        end

        aasm.event :create_other_task do
          transitions :from => [:approved, :ready_to_publish, :other_task_creat], :to => :other_task_creat
        end

        before_validation(:pre_process_parent_task, :on => :create)
        after_create :post_process_parent_task

        scope :visible_in_my_tasks, ->{where("tasks.state NOT IN ('unassigned', 'ready_to_publish', 'other_task_creat')")}

        has_reason_comment :_reject, :rejection, :editor, N_("Task rejected")
        has_reason_comment(:_abandon, :abandoning, :assignee, N_("Task abandoned")) do |task, opts|
          task.assignee = nil
        end
        has_reason_comment(:_help_required, :help_required, :assignee, N_("Help required")) do |task, opts|
          #task.assignee = nil
        end

        has_reason_comment(:finish, :finished, :assignee, N_("Task finished"), :allow_blank_messages => true) do |task, request_new_task|
          task.assignee.set_task_requested.save! if request_new_task.to_bool
        end
      end
  end

  def request_new_task
    true # always ask for new task when this one is done - default value
  end

  def should_have_assigned_peers?
    !unassigned?
  end

  def assign_editor(new_editor)
    self.editor = new_editor
    _assign
  end

  def assign_assignee(new_assignee)
    self.assignee = new_assignee
    if assignee_id_changed? && new_assignee
      new_assignee.task_requested_at = nil
      new_assignee.save
    end
    _assign
  end

  def assign!(new_editor = nil, new_assignee = nil)
    assign_editor(new_editor)
    assign_assignee(new_assignee)
    save!
  end

  def assign_by_user_ids!(new_editor_id, new_assignee_id)
    assign!(User.all_editors.find_by_id(new_editor_id.to_i), User.all_volunteers.find_by_id(new_assignee_id.to_i))
  end

  def abandon
    self.assignee = nil
    _abandon
  end
  def help_required
    self.s
  end

  def pre_process_parent_task
    return if parent_id.blank?

    begin
      parent.create_other_task
      parent.save!
    rescue AASM::InvalidTransition, ActiveRecord::RecordInvalid
      @parent_task_can_be_updated = true
    end

    if self.comments.first
      self.comments.first.user_id = self.creator_id
    end
  end

  def clone_parent_documents
    parent.documents.each do |doc|
      d = doc.dup
      d.task_id = self.id
      d.file = Paperclip.io_adapters.for(doc.file)
      d.save
    end
  end

  def post_process_parent_task
    return if parent_id.blank?
    clone_parent_documents
  end

  def build_chained_task(opts, actor) # opts -> name, kind, difficulty, full_nikkud
    new_task = Task.new(opts)
    new_task.editor = new_task.creator = actor
    new_task.parent_id = self.id
    # copy over custom property columns (migrated from custom_properties)
    new_task.orig_lang = self.orig_lang
    new_task.rashi = self.rashi
    new_task.instructions = self.instructions
    new_task
  end
  def events_for_current_state
    self.aasm.events.map(&:name)
  end
  def simple_assignee_events
    events_for_current_state.collect(&:task_event_cleanup) & ["help_required", "finish_partialy"]
  end

  def can_be_finished?
    events_for_current_state.member?(:finish)
  end

  def simple_editor_events
    events_for_current_state.collect(&:task_event_cleanup) & ["approve", "to_techedit", "complete"]
  end

  def can_be_rejected?
    events_for_current_state.member?(:_reject)
  end

  def can_be_abandoned?
    events_for_current_state.member?(:_abandon)
  end
  def can_be_help_requireded?
    events_for_current_state.member?(:_help_required)
  end

  def can_create_new_task?
    events_for_current_state.member?(:create_other_task)
  end

  def admin_state
    state
  end

  def admin_state=(value)
    self.state = value
  end

  EDITOR_EVENTS = [:reject, :complete, :create_other_task, :approve, :to_techedit, :help_required]
  ASSIGNEE_EVENTS = [:abandon, :finish, :help_required, :finish_partially]

  def allow_event_for?(event, user)
    return false if event.blank?
    return true if user.is_editor?
    return false unless participant?(user)
    eventnames = Task.aasm.events.map(&:name)
    return false unless eventnames.include?(event.to_sym) || eventnames.include?(('_'+event).to_sym)
#    return false unless Task.aasm.events.collect(&:first).collect(&:task_event_cleanup).member?(event.to_s)

    return true if assignee?(user) && ASSIGNEE_EVENTS.member?(event.to_sym)
    return true if editor?(user) && EDITOR_EVENTS.member?(event.to_sym)

    false
  end
end
