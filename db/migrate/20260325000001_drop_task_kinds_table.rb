class DropTaskKindsTable < ActiveRecord::Migration[6.1]
  def up
    drop_table :task_kinds
  end

  def down
    create_table :task_kinds, id: :integer, charset: 'utf8mb3' do |t|
      t.string :name
      t.timestamps
    end

    # Re-seed canonical kinds with their historical IDs
    {
      1  => 'הקלדה',
      11 => 'אחר',
      21 => 'הגהה',
      31 => 'חיפוש ביבליוגרפי',
      41 => 'גיוס כספים',
      51 => 'רשות פרסום',
      61 => 'עריכה טכנית',
      71 => 'סריקה',
      81 => 'חקיקה',
      91 => 'פרסים'
    }.each do |id, name|
      execute "INSERT INTO task_kinds (id, name, created_at, updated_at) VALUES (#{id}, '#{name}', NOW(), NOW())"
    end
  end
end
