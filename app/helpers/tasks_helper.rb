module TasksHelper
  TASK_EVENTS = {
    # editor
    "approve" => N_("task event|Approve"),
    "reject" => N_("task event|Reject"),
    "complete" => N_("task event|Mark as Completed"),
    "create_other_task" => N_("task event|Create Other Task"),
    # assignee
    "finish" => N_("task event|Finish"),
    "abandon" => N_("task event|Abandon"),
    "help_required" => N_("task event|Need Editor's Help"),
    "finish_partially" => N_("task event|Mark as Finished Partly"),
    "to_techedit" => N_("task event|Mark for technical editing")
  }

  def order_direction(param)
    param == "ASC" ? "DESC" : "ASC"
  end

  def textify_event(event)
    # TODO: gettext here
    s_(TASK_EVENTS[event])
  end

  def textify_full_nikud(task)
    task.full_nikkud ? _("Full Nikkud") : _("No")
  end
  def textify_rashi(task)
    task.rashi ? _("Yes") : _("No")
  end
  def upload_javascripts
    session_key = Rails.application.config.session_options[:key]
    javascript_tag <<-EOJS
    $(function() {
      var script_data = {format: 'js'};
      script_data[$('meta[name=csrf-param]').attr('content')] = encodeURI($('meta[name=csrf-token]').attr('content'));
      script_data[#{session_key.to_json}] = #{cookies[session_key].to_json};
      $("#upload_documents").uploadifive({
        'method'         : 'POST',
        'uploadScript'       : #{task_documents_path(@task).to_json},
        'formData'       : script_data,
        'fileObjName'    : 'document[file]',
        'auto'           : true,
        'multi'          : true,
        'fileTypeDesc'   : #{_('Choose files to attach to the project:').to_json},
        'queueID'        : 'fileQueue',
        'fileSizeLimit'  : 9*1024*1024,
        'successTimeout' : 42600,
        'onUploadSuccess': function(file, data, response) {
          eval(data);
        },
        'onUploadError'  : function(file, errorCode, errorMsg, errorString) {
          if (errorString == 'Cancelled') return;
          alert(#{_('Opps, something went wrong. Please try again later.').to_json});
          alert(errorString+' Error ('+errorCode+'): '+errorMsg);
          window.location.href = window.location.href;
        }
      });
      $("#upload_documents > object").css({top: 0, right: 0});  // FFFFFF uploadify
    });
    EOJS
  end

  def has_rejection_errors?
    @task.rejection_comment && !@task.rejection_comment.errors.blank?
  end

  def has_abandoning_errors?
    @task.abandoning_comment && !@task.abandoning_comment.errors.blank?
  end

  def link_to_task_participant_email(task, role, text)
    return if task.send(role).blank? || task.send(role).disabled?
    return if :assignee == role && !task.editor?(current_user)

    mail_to task.send(role).email, text, :body => task_url(task), :subject => (_("Re: BenYehuda task: #%{task}") % { :task => task.id.to_s })
  end

  def toggle_chained_js
    "jQuery('#new_task_link, #new_task_container').toggle();"
  end

  def task_kinds_for_select(val_attr = :id)
    TaskKind.all.map{|k| [k.name, k.send(val_attr)]}
  end

  def task_states_for_select
    Task.aasm_states.collect(&:name).collect(&:to_s).map{|s| [Task.textify_state(s), s]}
  end

  def task_difficulties_for_select
    Task::DIFFICULTIES.keys.map{|k| [Task.textify_difficulty(k), k]}
  end

  def task_length_for_select
    [[s_("task length|Short"), "short"], [s_("task length|Medium"), "medium"], [s_("task length|Long"), "long"]]
  end
  def task_priorities_for_select
    Task::PRIORITIES.keys.map{|k| [Task.textify_priority(k), k]}

#    [[s_("priority|First task of new volunteer"), "first"], [s_("priority|Very old task"), "very_old"], [s_("priority|Copyright expiring"), "expiry"], [s_("priority|Given permission"), "permission"], [s_("priority|Completing an author"), "completing"]]
  end
  def commentable_event_form(event)
    return unless @task.send("can_be_#{event}ed?")
    haml_tag(:div, :id => "#{event}_task") do
      haml_concat render(:partial => "tasks/#{event}")
    end
  end
end
