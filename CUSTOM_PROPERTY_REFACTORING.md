# CustomProperty Refactoring Summary

## Overview
This document describes the refactoring of the CustomProperty mechanism, replacing it with standard ActiveRecord model attributes and database columns.

## What Was Changed

### 1. Database Migrations

#### Added Columns
- **tasks table:**
  - `orig_lang` (string, 255 chars) - Original language of the work
  - `rashi` (boolean, default: false) - Whether Rashi script is used
  - `instructions` (text) - Special instructions for the task

- **users table:**
  - `volunteer_preferences` (text) - Volunteer preferences and comments

#### Data Migration
Created migrations to copy data from `custom_properties` table to new columns:
- `migrate_task_custom_properties_to_columns.rb` - Migrates Task properties
- `migrate_user_custom_properties_to_columns.rb` - Migrates User properties

Both migrations are reversible for safety.

#### Table Removal
Created `drop_custom_property_tables.rb` migration to remove:
- `custom_properties` table (polymorphic join table)
- `properties` table (metadata table)

### 2. Model Changes

#### Task Model (`app/models/task.rb`)
- Removed `has_many_custom_properties :task`
- Removed custom property accessors that queried `task_properties`
- Added simple getter methods for `orig_lang` and `instructions` that return empty string as default
- `rashi` is now a boolean column with ActiveRecord default handling
- `legacy_source` method now just returns the `source` column value

Property ID mappings removed:
- PROP_SOURCE = 131 (already had `source` column)
- PROP_ORIGLANG = 132 → now `orig_lang` column
- PROP_RASHI = 121 → now `rashi` column
- PROP_INSTRUCTIONS = 61 → now `instructions` column

#### User Model (`app/models/user.rb`)
- Removed `has_many_custom_properties :user`
- Removed `has_many_custom_properties :volunteer`
- Removed `has_many_custom_properties :editor`
- Updated `get_volunteer_preferences` to read from column
- Updated `set_volunteer_preferences` to write to column
- Updated `volunteer_preferences` method to read from attribute

Property ID mapping removed:
- PROP_VOL_PREFERENCES = 21 → now `volunteer_preferences` column

#### VolunteerRequest Model (`app/models/volunteer_request.rb`)
- Removed `has_many_custom_properties :request`
- No specific properties were used, so just removed the association

### 3. Controller Changes

#### AdminTasksController (`app/controllers/admin/tasks_controller.rb`)
- Updated `prepare_cloned_task` method to copy columns instead of custom properties:
  ```ruby
  t.orig_lang = task.orig_lang
  t.rashi = task.rashi
  t.instructions = task.instructions
  ```

#### States Module (`app/models/states.rb`)
- Updated `build_chained_task` method to copy columns instead of custom properties

### 4. View Changes

#### Task Forms
- `app/views/admin/tasks/_form.html.haml`:
  - Removed `custom_properties_fields(f, "task")` helper call
  - Added explicit form fields:
    - `instructions` (textarea)
    - `orig_lang` (text input)
    - `rashi` (checkbox)

#### User Forms
- `app/views/users/_volunteer_form.html.haml`:
  - Removed `custom_properties_fields(f, "volunteer")`
  - No replacement needed (volunteer_preferences set via approve! method)
  
- `app/views/users/_editor_form.html.haml`:
  - Removed `custom_properties_fields(f, "editor")`
  - No replacement needed (no specific editor properties used)
  
- `app/views/users/_user_form.html.haml`:
  - Removed `custom_properties_fields(f, "user")`
  - No replacement needed (no specific user properties used)

### 5. Deprecation Notices Added

Added deprecation comments to:
- `app/models/custom_property.rb`
- `app/models/property.rb`
- `lib/custom_properties.rb`
- `app/helpers/properties_helper.rb`
- `app/controllers/properties_controller.rb`

Commented out routes:
- `config/routes.rb` - commented out `resources :properties`

## Migration Path

### To Apply These Changes:

1. Run migrations in order:
   ```bash
   rails db:migrate:up VERSION=20251123040900  # Add columns to tasks
   rails db:migrate:up VERSION=20251123041000  # Add columns to users
   rails db:migrate:up VERSION=20251123041100  # Migrate task data
   rails db:migrate:up VERSION=20251123041200  # Migrate user data
   ```

2. Test the application thoroughly

3. Once verified, drop old tables:
   ```bash
   rails db:migrate:up VERSION=20251123041300  # Drop old tables
   ```

### To Rollback:

All migrations are reversible:
```bash
rails db:rollback STEP=5
```

## Backward Compatibility

- All getter methods maintain the same interface
- Default values are preserved (empty strings, false booleans)
- Existing code accessing `task.instructions`, `task.orig_lang`, etc. continues to work
- `user.volunteer_preferences` accessor method preserved

## Benefits

1. **Simpler Data Model**: Direct column access instead of polymorphic associations
2. **Better Performance**: No joins needed to fetch custom properties
3. **Type Safety**: Proper column types (boolean, text) instead of string representations
4. **Clearer Schema**: Properties are explicit in the schema
5. **Easier Queries**: Can query and filter on properties directly
6. **Standard Forms**: Regular form fields instead of dynamic property rendering

## Testing Notes

- No new tests added (minimal change requirement)
- Existing tests should continue to work as model interfaces are preserved
- Manual testing recommended for:
  - Task creation/editing with instructions, orig_lang, rashi
  - Task cloning (split_task, build_chained_task)
  - Volunteer request approval (volunteer_preferences transfer)
  - Task display showing instructions

## Security Review

- CodeQL security scan passed with 0 alerts
- No SQL injection risks (using ActiveRecord properly)
- No new external dependencies
- Data migration uses parameterized SQL

## Files Modified

### Created:
- `db/migrate/20251123040900_add_custom_property_columns_to_tasks.rb`
- `db/migrate/20251123041000_add_volunteer_preferences_to_users.rb`
- `db/migrate/20251123041100_migrate_task_custom_properties_to_columns.rb`
- `db/migrate/20251123041200_migrate_user_custom_properties_to_columns.rb`
- `db/migrate/20251123041300_drop_custom_property_tables.rb`

### Modified:
- `app/models/task.rb`
- `app/models/user.rb`
- `app/models/volunteer_request.rb`
- `app/models/custom_property.rb` (deprecation notice)
- `app/models/property.rb` (deprecation notice)
- `app/controllers/admin/tasks_controller.rb`
- `app/controllers/properties_controller.rb` (deprecation notice)
- `app/models/states.rb`
- `app/views/admin/tasks/_form.html.haml`
- `app/views/users/_volunteer_form.html.haml`
- `app/views/users/_editor_form.html.haml`
- `app/views/users/_user_form.html.haml`
- `app/helpers/properties_helper.rb` (deprecation notice)
- `lib/custom_properties.rb` (deprecation notice)
- `config/routes.rb`

## Future Cleanup (Optional)

After confirming the refactoring is working correctly in production:

1. Remove deprecated model files:
   - `app/models/custom_property.rb`
   - `app/models/property.rb`

2. Remove deprecated helper/module files:
   - `app/helpers/properties_helper.rb`
   - `lib/custom_properties.rb`

3. Remove deprecated controller:
   - `app/controllers/properties_controller.rb`

4. Remove deprecated views:
   - `app/views/properties/` directory

5. Remove test files:
   - `old_spec/models/custom_property_spec.rb`
   - Related controller specs

6. Remove unused constants from models:
   - `Task::PROP_SOURCE`, `PROP_ORIGLANG`, `PROP_RASHI`, `PROP_INSTRUCTIONS`
   - `User::PROP_VOL_PREFERENCES`
