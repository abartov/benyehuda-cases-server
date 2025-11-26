class Notification < ActionMailer::Base

  include TasksHelper
  helper :tasks

  def comment_added(comment, recipient_users, from_user)
    @comment = comment
    @task_url = task_url(comment.task)
    mail to: recipient_users.collect(&:email_recipient), from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('comment_added_notification_subject.task_name_snippet_new_comment', task_name_snippet: comment.task.name.utf_snippet(70), domain: domain)
  end

  def task_state_changed(task, recipient_users)
    @task = task
    @task_url = task_url(task)
    mail to: recipient_users.collect(&:email_recipient), from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('state_changed_notification_subject.state_domain_task_name_snippet', state: Task.textify_state(task.state), task_name_snippet: task.name.utf_snippet(20), domain: domain)
  end

  def task_published(task, recipient_users)
    @task = task
    @task_url = task_url(task)
    mail to: recipient_users.collect(&:email_recipient), from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: "המשימה '#{task.name.utf_snippet(20)}' פורסמה באתר"
  end

  def volnteer_welcome(user)
    @user = user
    @domain = domain
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('volunteer_welcome_subject.welcome_to_ben_yehuda_project')
  end

  def tasks_added_to_site(user)
    @user = user
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('your_work_added_to_site_subject.your_contributions_are_now_published')
  end

  def team_mass_message(user, team, message)
    @user = user
    @team = team
    @message = message.gsub("\n", "<br>")
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t(:team_mass_message, team: team.name)
  end

  def volunteer_returned_from_break(volunteer, editor)
    @volunteer = volunteer
    @editor = editor
    @domain = domain
    mail to: editor.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('gettext.volunteer_returned_from_break', volunteer_name: volunteer.name)
  end

protected

  def domain
    if domain = GlobalPreference.get(:domain)
      default_url_options[:host] = domain
    end
    @domain ||= domain
  end

  def from_address
    GlobalPreference.get(:notifications_default_email) || "asaf.bartov@gmail.com"
  end
end
