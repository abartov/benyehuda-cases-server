# Be sure to restart your server when you modify this file.

#CasesServer::Application.config.session_store :cookie_store, :key => '_cases_server_session'
CasesServer::Application.config.session_store :active_record_store, :key => '_cases_server_session31'
#CasesServer::Application.config.session_store :active_record_store, :key => '_uploader_session'

#CasesServer::Application.config.session_store :active_record_store

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# CasesServer::Application.config.session_store :active_record_store

## old stuff needed for inserting the session cookie into Flash requests
#Rails.application.config.middleware.insert_before(
#  Rails.application.config.session_store,
#  FlashSessionCookieMiddleware,
#  Rails.application.config.session_options[:key]
#)
