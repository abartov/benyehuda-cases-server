class Notification < ActionMailer::Base

  include TasksHelper
  helper :tasks

  # A recipient who accumulated hundreds of buffered notifications would
  # otherwise get a mail their provider may truncate or reject outright,
  # costing them the whole digest rather than its tail.
  DIGEST_ITEM_LIMIT = 30

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
    mail to: user.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: I18n.t('anniversary.email_subject', count: @years, years: @years)
  end

  def task_idle(task, assignee, editor)
    @task = task
    @assignee = assignee
    @editor = editor
    @task_url = task_url(task)
    @domain = domain
    recipients = [assignee.email_recipient]
    recipients << editor.email_recipient if editor && editor.email_recipient != assignee.email_recipient
    mail to: recipients, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: "תזכורת: משימה #{task.name.utf_snippet(30)} ממתינה להשלמה"
  end

  def editor_idle_tasks_report(editor, idle_tasks_data)
    @editor = editor
    @idle_tasks_data = idle_tasks_data
    @domain = domain
    mail to: editor.email_recipient, from: "Project Ben-Yehuda <editor@benyehuda.org>", subject: "דו\"ח שבועי: משימות ללא התקדמות"
  end

  # One aggregate email standing in for several buffered notifications.
  #
  # +items+ is a list of [PendingNotification, occurrences] pairs as produced by
  # PendingNotification.collapse; +omitted_count+ is how many further
  # notifications were dropped by DIGEST_ITEM_LIMIT and are reported as a count.
  def notification_digest(recipient_email, items, omitted_count = 0)
    @recipient_email = recipient_email
    @user = User.find_by(email: recipient_email)
    @omitted_count = omitted_count
    @domain = domain
    # Each item is rendered by invoking its original mailer method and embedding
    # the result, so digest content stays in sync with the individual emails and
    # there is no second set of templates to maintain.
    @entries = items.map do |(pending, occurrences)|
      { body: render_buffered_notification(pending), occurrences: occurrences }
    end
    total = items.sum { |(_pending, occurrences)| occurrences } + omitted_count
    mail to: recipient_email, from: "Project Ben-Yehuda <editor@benyehuda.org>",
         subject: I18n.t('notification_digest.subject', count: total)
  end

protected

  def render_buffered_notification(pending)
    message = pending.mailer_class.public_send(pending.mailer_method, *pending.deserialized_args).message
    part = message.multipart? ? (message.text_part || message.html_part) : message
    body = part.body.decoded
    body = ActionController::Base.helpers.strip_tags(body) if part.content_type.to_s.include?('text/html')
    body.strip
  rescue StandardError => e
    # One bad item must not lose the whole digest.
    Rails.logger.warn("Notification#notification_digest: could not render #{pending.notification_type}: " \
                      "#{e.class}: #{e.message}")
    I18n.t('notification_digest.render_failed')
  end

  def domain
    @domain ||= SiteConstants::APP_HOSTNAME
  end

  def from_address
    SiteConstants::NOTIFICATIONS_DEFAULT_EMAIL
  end
end
