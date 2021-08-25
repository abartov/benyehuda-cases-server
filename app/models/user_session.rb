class UserSession < Authlogic::Session::Base
  extend ActiveModel::Naming
  remember_me_for 60.days
  remember_me true
end