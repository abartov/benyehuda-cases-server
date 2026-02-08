class AddCustomPropertyColumnsToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column :tasks, :orig_lang, :string, limit: 255
    add_column :tasks, :rashi, :boolean, default: false
    add_column :tasks, :instructions, :text
  end
end
