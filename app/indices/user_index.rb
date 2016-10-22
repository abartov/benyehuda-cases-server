
ThinkingSphinx::Index.define :user, :with => :active_record do
  indexes :name, :sortable => true
  indexes :email, :sortable => true
  indexes kind.name, :sortable => true, :as => :kind
  has :disabled_at
  has :activated_at
  has :current_login_at
end

