# DEPRECATED: CustomProperties module has been replaced by individual columns
# This module is kept for reference but should not be used in new code
# Migration completed: 2025-11-23

module CustomProperties
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def has_many_custom_properties(parent_name, association_name = nil)
      parent_name = parent_name.to_s.downcase
      raise "Wrong CustomProperty '#{parent_name}' not in a list of Property::PARENTS" unless Property::PARENTS.member?(parent_name.capitalize)

      association_name = (association_name || "#{parent_name}_properties").to_sym

      has_many association_name, ->{ joins(:property).includes(:property).where("properties.parent_type = '#{parent_name.capitalize}'") }, :class_name => "CustomProperty", :as => :proprietary, :validate => false do
        def indexed_by_id
          @indexed_by_id ||= index_by(&:property_id)
        end
      end

#      attr_accessible association_name

      define_method "#{association_name}=" do |opts|
        opts.each do |property_id, attrs|
          cp = !new_record? && self.send(association_name).detect {|up| up.property_id == property_id.to_i}
          cp ||= self.send(association_name).build(:property_id => property_id)
          cp.attributes = attrs
        end
      end

      define_method "save_#{association_name}" do
        self.send(association_name).each do |rp|
          rp.save if rp.changed?
        end
      end

      cbsym = "save_#{association_name}".to_sym
      after_save cbsym
    end
  end
end