domain = (GlobalPreference.get(:domain) || "benyehuda.org") rescue "benyehuda.org"
ActionMailer::Base.smtp_settings = {
  :address => "localhost",
  :port => 25,
  :domain => domain,
  :enable_starttls_auto => false  # XXX maybe to set through global preferences
}
