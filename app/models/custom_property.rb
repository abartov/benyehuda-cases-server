# DEPRECATED: CustomProperty has been migrated to individual columns
# This model is kept for reference but should not be used in new code
# Migration completed: 2025-11-23
# See migrations: 20251123040900_add_custom_property_columns_to_tasks.rb
#                20251123041000_add_volunteer_preferences_to_users.rb
#                20251123041100_migrate_task_custom_properties_to_columns.rb
#                20251123041200_migrate_user_custom_properties_to_columns.rb

class CustomProperty < ActiveRecord::Base
  belongs_to :proprietary, :polymorphic => true
  belongs_to :property

  validates :property_id, :proprietary_id, :proprietary_type, :presence => true

  validates :property_id, :uniqueness => { :scope => [:proprietary_id, :proprietary_type] }

#  attr_accessible :property_id, :custom_value

  scope :visible_for, lambda { |user|
    user.admin_or_editor? ? where("") : where("properties.is_public = 1")
  }
end
