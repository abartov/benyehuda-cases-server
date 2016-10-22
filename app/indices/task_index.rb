
ThinkingSphinx::Index.define :task, :with => :active_record do
  indexes name, :sortable => true

  has created_at, updated_at
  has :full_nikkud, :type => :boolean
  indexes :difficulty, :sortable => true
  indexes :priority, :sortable => true
  indexes kind.name, :sortable => true, :as => :kind
  indexes :state, :sortable => true
  has :documents_count, :type => :integer

end

