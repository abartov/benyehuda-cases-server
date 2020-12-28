index_name = ENV['is_staging'] == 'true' ? 'staging_task' : 'task'

ThinkingSphinx::Index.define :task, name: index_name, with: :active_record do
  indexes name, :sortable => true

  has created_at, updated_at, genre
  has :full_nikkud, :type => :boolean
  has :independent, :type => :boolean
  has :include_images, :type => :boolean
  indexes :source
  indexes :difficulty, :sortable => true
  indexes :priority, :sortable => true
  indexes kind.name, :sortable => true, :as => :kind
  indexes :state, :sortable => true
  has :documents_count, :type => :integer

end