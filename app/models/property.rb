# DEPRECATED: Property has been migrated to individual columns
# This model is kept for reference but should not be used in new code
# Migration completed: 2025-11-23

class Property < ActiveRecord::Base

  PARENTS = %w(User Volunteer Editor Task Request)
  TYPES = %w(string text boolean)

  validates :title, :parent_type, :property_type, :presence => true
  validates :parent_type, :inclusion => { :in => PARENTS }
  validates :property_type, :inclusion => { :in => TYPES }
  validates :title, :uniqueness => { :scope => :parent_type }

#  attr_accessible :title, :parent_type, :property_type, :is_public, :comment

  scope :by_parent_type_and_title, ->{order("properties.parent_type, properties.title")}

  PARENTS.each do |parent|
    scope "available_for_#{parent.downcase}".to_sym, lambda {|user|
      conditions = ["properties.parent_type  = ?", parent]

      conditions.first << " AND properties.is_public = 1" unless user.admin_or_editor?

      where(conditions)
    }
  end

  has_many :custom_properties
end
