index_name = ENV['is_staging'] == 'true' ? 'staging_task' : 'task'

ThinkingSphinx::Index.define :task, name: index_name, with: :active_record do
  join teams
  indexes name, sortable: true
  indexes assignee.name, sortable: true, as: :assignee
  indexes creator.name, sortable: true, as: :creator
  indexes editor.name, sortable: true, as: :editor
  has created_at, updated_at, genre
  has :full_nikkud, type: :boolean
  has :independent, type: :boolean
  has :include_images, type: :boolean
  indexes :source
  indexes :difficulty, sortable: true
  indexes :priority, sortable: true
  has :kind_id, type: :integer
  indexes :state, sortable: true
  has :documents_count, type: :integer
  indexes teams(:id), as: :teams, multi: true
  indexes project(:id), as: :project
end
