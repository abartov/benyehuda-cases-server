module TaskNotifications

  SKIP_STATES = [:unassigned, :other_task_creat]

  def self.included(base)
    base.class_eval do
      before_save :remember_changes
      after_save :delayed_notify_on_changes
    end
  end

  def remember_changes # quick fix for changed behavior after Rails upgrade
    @was_state_changed = state_changed?
    @was_editor_id_changed = editor_id_changed?
    @was_assignee_id_changed = assignee_id_changed?
  end

  def task_changes_recipients(comment = nil)
    state_changed_by = []
    state_changed_for = []
    if @was_state_changed || comment
      state_changed_for << assignee
      state_changed_for << editor if comment.present? || self.state != 'ready_to_publish'
      state_changed_by << comment.user if comment.try(:user)
    elsif @was_editor_id_changed || @was_assignee_id_changed
      state_changed_for << editor if @was_editor_id_changed
      state_changed_for << assignee if @was_assignee_id_changed
    else
      return nil
    end

    (state_changed_for.compact.uniq - state_changed_by)
  end

  # XXX
  def delayed_notify_on_changes
    return if SKIP_STATES.member?(state.to_sym)
    recipients = (task_changes_recipients || []).select {|r| r.wants_to_be_notified_of?(:state)}
    return if recipients.blank?

    cond = @was_state_changed
    cond = false unless state == 'ready_to_publish'
    if cond
    #if @was_stated_changed && self.state == 'ready_to_publish'
      I18n.with_locale('he') { Notification.task_published(self, recipients).deliver }
    else
      I18n.with_locale('he') { Notification.task_state_changed(self, recipients).deliver }
    end
  end
end
