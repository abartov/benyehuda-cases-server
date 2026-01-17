class MigrateTaskCustomPropertiesToColumns < ActiveRecord::Migration[6.0]
  def up
    # Migrate PROP_ORIGLANG = 132
    execute <<-SQL
      UPDATE tasks t
      INNER JOIN custom_properties cp ON cp.proprietary_id = t.id 
        AND cp.proprietary_type = 'Task' 
        AND cp.property_id = 132
      SET t.orig_lang = cp.custom_value
      WHERE cp.custom_value IS NOT NULL AND cp.custom_value != ''
    SQL

    # Migrate PROP_RASHI = 121
    execute <<-SQL
      UPDATE tasks t
      INNER JOIN custom_properties cp ON cp.proprietary_id = t.id 
        AND cp.proprietary_type = 'Task' 
        AND cp.property_id = 121
      SET t.rashi = IF(cp.custom_value IN ('1', 'true', 'yes'), 1, 0)
      WHERE cp.custom_value IS NOT NULL
    SQL

    # Migrate PROP_INSTRUCTIONS = 61
    execute <<-SQL
      UPDATE tasks t
      INNER JOIN custom_properties cp ON cp.proprietary_id = t.id 
        AND cp.proprietary_type = 'Task' 
        AND cp.property_id = 61
      SET t.instructions = cp.custom_value
      WHERE cp.custom_value IS NOT NULL AND cp.custom_value != ''
    SQL
  end

  def down
    # Reverse migration - restore from columns to custom_properties
    # PROP_ORIGLANG = 132
    execute <<-SQL
      INSERT INTO custom_properties (property_id, proprietary_id, proprietary_type, custom_value, created_at, updated_at)
      SELECT 132, id, 'Task', orig_lang, NOW(), NOW()
      FROM tasks
      WHERE orig_lang IS NOT NULL AND orig_lang != ''
      AND NOT EXISTS (
        SELECT 1 FROM custom_properties cp2 
        WHERE cp2.proprietary_id = tasks.id 
        AND cp2.proprietary_type = 'Task' 
        AND cp2.property_id = 132
      )
    SQL

    # PROP_RASHI = 121
    execute <<-SQL
      INSERT INTO custom_properties (property_id, proprietary_id, proprietary_type, custom_value, created_at, updated_at)
      SELECT 121, id, 'Task', IF(rashi = 1, 'true', 'false'), NOW(), NOW()
      FROM tasks
      WHERE rashi IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM custom_properties cp2 
        WHERE cp2.proprietary_id = tasks.id 
        AND cp2.proprietary_type = 'Task' 
        AND cp2.property_id = 121
      )
    SQL

    # PROP_INSTRUCTIONS = 61
    execute <<-SQL
      INSERT INTO custom_properties (property_id, proprietary_id, proprietary_type, custom_value, created_at, updated_at)
      SELECT 61, id, 'Task', instructions, NOW(), NOW()
      FROM tasks
      WHERE instructions IS NOT NULL AND instructions != ''
      AND NOT EXISTS (
        SELECT 1 FROM custom_properties cp2 
        WHERE cp2.proprietary_id = tasks.id 
        AND cp2.proprietary_type = 'Task' 
        AND cp2.property_id = 61
      )
    SQL
  end
end
