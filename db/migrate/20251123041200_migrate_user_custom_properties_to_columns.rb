class MigrateUserCustomPropertiesToColumns < ActiveRecord::Migration[6.0]
  def up
    # Migrate PROP_VOL_PREFERENCES = 21 to volunteer_preferences
    execute <<-SQL
      UPDATE users u
      INNER JOIN custom_properties cp ON cp.proprietary_id = u.id 
        AND cp.proprietary_type = 'User' 
        AND cp.property_id = 21
      SET u.volunteer_preferences = cp.custom_value
      WHERE cp.custom_value IS NOT NULL AND cp.custom_value != ''
    SQL
  end

  def down
    # Reverse migration - restore from columns to custom_properties
    execute <<-SQL
      INSERT INTO custom_properties (property_id, proprietary_id, proprietary_type, custom_value, created_at, updated_at)
      SELECT 21, id, 'User', volunteer_preferences, NOW(), NOW()
      FROM users
      WHERE volunteer_preferences IS NOT NULL AND volunteer_preferences != ''
      AND NOT EXISTS (
        SELECT 1 FROM custom_properties cp2 
        WHERE cp2.proprietary_id = users.id 
        AND cp2.proprietary_type = 'User' 
        AND cp2.property_id = 21
      )
    SQL
  end
end
