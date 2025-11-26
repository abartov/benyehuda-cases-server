module VolunteerRequestsHelper
  def confirm_button(volunteer_request)
    link_to I18n.t('gettext.confirm'), volunteer_request_path(volunteer_request), :method => :put, :confirm => I18n.t('gettext.are_you_sure')
  end
end
