class Notification < ActionMailer::Base

  include TasksHelper
  helper :tasks

  def comment_added(comment, recipient_users, from_user)
    @comment = comment
    @task_url = task_url(comment.task)
    mail to: recipient_users.collect(&:email_recipient), from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: s_("comment added notification subject|%{task_name_snippet} - New comment") % {:task_name_snippet => comment.task.name.utf_snippet(70), :domain => domain}
  end

  def task_state_changed(task, recipient_users)
    @task = task
    @task_url = task_url(task)
    mail to: recipient_users.collect(&:email_recipient), from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: s_("state changed notification subject|%{state} (%{domain}): %{task_name_snippet}") % { :state => Task.textify_state(task.state), :task_name_snippet => task.name.utf_snippet(20), :domain => domain}
  end

  def task_published(task, recipient_users)
    @task = task
    @task_url = task_url(task)
    mail to: recipient_users.collect(&:email_recipient), from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: "המשימה '#{task.name.utf_snippet(20)}' פורסמה באתר"
  end

  def volnteer_welcome(user)
    @user = user
    @domain = domain
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: s_("volunteer welcome subject|Welcome to Ben Yehuda Project")
  end

  def tasks_added_to_site(user)
    @user = user
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: s_("your work added to site subject|Your contributions are now published on the Ben-Yehuda site!")
  end

  def team_mass_message(user, team, message)
    @user = user
    @team = team
    @message = message.gsub("\n", "<br>")
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: t(:team_mass_message, team: team.name)
  end

  def volunteer_returned_from_break(volunteer, editor)
    @volunteer = volunteer
    @editor = editor
    @domain = domain
    mail to: editor.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: s_("Volunteer %{volunteer_name} has returned from break") % { volunteer_name: volunteer.name }
  end

  def anniversary_greeting(user, sender, message)
    @user = user
    @sender = sender
    @message = message
    @years = user.years_since_joining
    @domain = domain
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('anniversary.email_subject', years: @years)
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
