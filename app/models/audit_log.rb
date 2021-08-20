class AuditLog < ActiveRecord::Base
  belongs_to :api_user
end
