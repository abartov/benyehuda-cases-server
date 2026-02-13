class MigrateUserCustomPropertiesToColumns < ActiveRecord::Migration[6.0]
  def change
    # Migrate PROP_VOL_PREFERENCES = 21 to volunteer_preferences
    execute <<-SQL
      UPDATE users u
      INNER JOIN custom_properties cp ON cp.proprietary_id = u.id#{' '}
        AND cp.proprietary_type = 'User'#{' '}
        AND cp.property_id = 21
      SET u.volunteer_preferences = cp.custom_value
      WHERE cp.custom_value IS NOT NULL AND cp.custom_value != ''
    SQL
    # Migrate PROP_VOL_PREFERENCES = 1 to volunteer_preferences
    execute <<-SQL
      UPDATE users u
      INNER JOIN custom_properties cp ON cp.proprietary_id = u.id#{' '}
        AND cp.proprietary_type = 'User'#{' '}
        AND cp.property_id = 1
      SET u.address = cp.custom_value
      WHERE cp.custom_value IS NOT NULL AND cp.custom_value != ''
    SQL
    # Migrate PROP_VOL_PREFERENCES = 71 to volunteer_preferences
    execute <<-SQL
      UPDATE users u
      INNER JOIN custom_properties cp ON cp.proprietary_id = u.id#{' '}
        AND cp.proprietary_type = 'User'#{' '}
        AND cp.property_id = 71
      SET u.telephone = cp.custom_value
      WHERE cp.custom_value IS NOT NULL AND cp.custom_value != ''
    SQL
  end
end
