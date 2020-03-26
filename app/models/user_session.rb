class UserSession < Authlogic::Session::Base
  extend ActiveModel::Naming
  remember_me_for 30.days
  remember_me true
end