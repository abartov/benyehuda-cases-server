# encoding: utf-8
#
# Reference data: the lookup rows the application code expects to exist in
# every environment. Extracted from the development database (a snapshot of
# production) on 2026-08-28, and kept idempotent so it is safe to re-run.
#
# IDs are pinned to the production values on purpose. They are not cosmetic:
# User::PROP_VOL_PREFERENCES hardcodes property id 21, so a test or development
# database that assigns its own ids silently behaves differently from production.
#
# This is *reference* data only -- no users, tasks or other content. Anything
# that a test should be able to invent for itself belongs in a factory, not here.

def seed_reference_row!(klass, id, attributes)
  record = klass.find_or_initialize_by(id: id)
  record.assign_attributes(attributes)
  record.save!(validate: false)
  record
end

# --- Task states -------------------------------------------------------------
#
# Task.textify_state looks these up by name and calls .value on the result, with
# no nil guard, so a missing row takes down any view that renders a task state.
# The names must stay in step with the aasm states declared in app/models/states.rb.
#
# `value` is a gettext msgid; N_() marks it for extraction without translating here.
[
  [1,  'unassigned',       N_("task state|Unassigned")],
  [11, 'assigned',         N_("task state|Assigned/Work in Progress")],
  [21, 'stuck',            N_("task state|Editors Help Required")],
  [31, 'partial',          N_("task state|Partialy Ready")],
  [41, 'waits_for_editor', N_("task state|Waits for Editor's approvement")],
  [51, 'rejected',         N_("task state|Rejected by Editor")],
  [61, 'approved',         N_("task state|Approved by Editor")],
  [71, 'ready_to_publish', N_("task state|Ready to Publish")],
  [81, 'other_task_creat', N_("task state|Another Task Created")],
  [91, 'techedit',         N_("task state|Technical editing")]
].each do |id, name, value|
  seed_reference_row!(TaskState, id, name: name, value: value)
end

# --- Volunteer kinds ---------------------------------------------------------
[
  [1,  'סריקה'],
  [11, 'עריכה טכנית'],
  [21, 'רשות פרסום']
].each do |id, name|
  seed_reference_row!(VolunteerKind, id, name: name)
end

# --- Properties --------------------------------------------------------------
#
# Property id 21 is the one User::PROP_VOL_PREFERENCES refers to; do not renumber.
[
  [1,   'כתובת',                    'User',      'string',  true],
  [11,  'טלפון נייד',                'User',      'string',  true],
  [21,  'העדפת הקלדה',               'Volunteer', 'text',    true],
  [31,  'סוג משימות עריכה מועדף',     'Editor',    'text',    true],
  [61,  'הנחיות מיוחדות למשימה זו',   'Task',      'text',    true],
  [71,  'טלפון',                     'User',      'string',  true],
  [81,  "מס' סידורי בקובץ הידני",     'Volunteer', 'string',  false],
  [91,  'הערות',                     'User',      'text',    false],
  [101, 'העדפת קרדיט',               'Volunteer', 'string',  true],
  [111, 'ניקוד מלא',                 'Request',   'boolean', true],
  [121, 'כתב רש"י',                  'Task',      'boolean', true],
  [132, 'שפת מקור',                  'Task',      'string',  true]
].each do |id, title, parent_type, property_type, is_public|
  seed_reference_row!(Property, id, title: title, parent_type: parent_type,
                                    property_type: property_type, is_public: is_public)
end
