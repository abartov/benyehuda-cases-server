#require 'config/initializers/i18n'

class CreateTaskKinds < ActiveRecord::Migration
  # Migration-local model to avoid depending on the app-level TaskKind constant
  # (which no longer exists after the enum refactor).
  class TaskKind < ActiveRecord::Base
    self.table_name = 'task_kinds'
  end

  KINDS = {  # deleted from app/models/task.rb
    "typing" => "typing",
    "proofing" => "proofing",
    "other" => "other"
  }
  def self.up
    create_table :task_kinds do |t|
      t.string :name
      t.timestamps
    end
    KINDS.each do |_k, v|
      TaskKind.create!(name: v)
    end
    rename_column :tasks, :kind, :old_kind
    add_column :tasks, :kind_id, :integer
    execute("SELECT id, old_kind FROM tasks WHERE old_kind IS NOT NULL AND old_kind != ''").each do |row|
      old_kind_name = KINDS[row['old_kind']] || row['old_kind']
      kind = TaskKind.find_or_create_by!(name: old_kind_name)
      execute("UPDATE tasks SET kind_id = #{kind.id} WHERE id = #{row['id']}")
    end
    remove_column :tasks, :old_kind
  end
  # NOTE the code must be updated appropriately (app/models/task.rb), not possible to migrate/rollback back and forth with the same code
  def self.down
    add_column :tasks, :kind, :string
    sdnik = KINDS.invert
    execute("SELECT id, kind_id FROM tasks WHERE kind_id IS NOT NULL").each do |row|
      k = TaskKind.find(row['kind_id']).name
      kind_str = sdnik[k] || k
      execute("UPDATE tasks SET kind = '#{kind_str.gsub("'", "''")}' WHERE id = #{row['id']}")
    end
    remove_column :tasks, :kind_id
    drop_table :task_kinds
  end
end
