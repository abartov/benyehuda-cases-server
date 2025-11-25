module TasksHelper
  TASK_EVENTS = {
    # editor
    'approve' => 'task_event.approve',
    'reject' => 'task_event.reject',
    'complete' => 'task_event.mark_as_completed',
    'create_other_task' => 'task_event.create_other_task',
    # assignee
    'finish' => 'task_event.finish',
    'abandon' => 'task_event.abandon',
    'help_required' => 'task_event.need_editors_help',
    'finish_partially' => 'task_event.mark_as_finished_partly',
    'to_techedit' => 'task_event.mark_for_technical_editing'
  }

  def order_direction(param)
    param == 'ASC' ? 'DESC' : 'ASC'
  end

  def sorting_path_for_current_context(params_to_merge = {})
    # Determine the correct path based on the current controller
    case controller_name
    when 'tasks'
      tasks_path(params_to_merge)
    when 'dashboards'
      dashboard_path(params_to_merge)
    when 'report'
      url_for(params.merge(params_to_merge))
    else
      # For other contexts, default to current path with params
      url_for(params.merge(params_to_merge))
    end
  end

  def textify_event(event)
    I18n.t(TASK_EVENTS[event])
  end

  def textify_full_nikud(task)
    task.full_nikkud ? I18n.t('gettext.full_nikkud') : I18n.t('gettext.no')
  end

  def textify_rashi(task)
    [true, 1, '1'].include?(task.rashi) ? I18n.t('gettext.yes') : I18n.t('gettext.no')
  end

  def has_rejection_errors?
    !@task.valid?
    # @task.rejection_comment && !@task.rejection_comment.errors.blank?
  end

  def has_abandoning_errors?
    false
    # @task.abandoning_comment && !@task.abandoning_comment.errors.blank?
  end

  def link_to_task_participant_email(task, role, text)
    return if task.send(role).blank? || task.send(role).disabled?
    return if :assignee == role && !task.editor?(current_user)

    mail_to task.send(role).email, text, body: task_url(task),
                                         subject: format(_('Re: BenYehuda task: #%<task>s'), task: task.id.to_s)
  end

  def toggle_chained_js
    "jQuery('#new_task_link, #new_task_container').toggle();"
  end

  def task_kinds_for_select(val_attr = :id)
    TaskKind.all.map { |k| [k.name, k.send(val_attr)] }
  end

  def task_states_for_select
    Task.aasm.states.collect(&:name).collect(&:to_s).map { |s| [Task.textify_state(s), s] }
  end

  def task_difficulties_for_select
    Task::DIFFICULTIES.keys.map { |k| [Task.textify_difficulty(k), k] }
  end

  def task_length_for_select
    [[I18n.t('task_length.short'), 'short'], [I18n.t('task_length.medium'), 'medium'], [I18n.t('task_length.long'), 'long']]
  end

  def task_priorities_for_select
    Task::PRIORITIES.keys.map { |k| [Task.textify_priority(k), k] }

    #    [[s_("priority|First task of new volunteer"), "first"], [s_("priority|Very old task"), "very_old"], [s_("priority|Copyright expiring"), "expiry"], [s_("priority|Given permission"), "permission"], [s_("priority|Completing an author"), "completing"]]
  end

  def commentable_event_form(event)
    return unless @task.send("can_be_#{event}ed?")

    content_tag(:div, id: "#{event}_task") do
      concat render(partial: "tasks/#{event}")
    end
  end
end
