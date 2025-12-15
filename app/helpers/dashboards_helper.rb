module DashboardsHelper
  def waiting_for_task(volunteer)
    return time_ago_in_words(volunteer.task_requested_at).dup if volunteer.task_requested_at.present?
    return "N/A"
  end

  def pending_volunteer_requests
    pending_count = VolunteerRequest.pending.count
    if pending_count > 0
      content_tag(:span, style: 'background-color: lightblue; color: yellow;') do
        concat link_to(I18n.t('gettext.pending_volunteer_requests', count: pending_count), volunteer_requests_path)
      end
    end
  end

  def link_to_assign_a_task(user)
    link_to tasks_path(:assignee_id => user.id, :per_page => 10, :kind => 'הקלדה').html_safe, :class => "ico", :method => :get,
      :onclick => "jQuery('#assign_now').html(#{I18n.t(:loading).to_json}).dialog('open');", :remote => true do
        content_tag(:span, I18n.t('gettext.assign_a_task'))
    end
  end
end
