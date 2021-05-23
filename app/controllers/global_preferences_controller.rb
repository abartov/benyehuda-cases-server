class GlobalPreferencesController < InheritedResources::Base
  unloadable
  include InheritedResources::DSL
  before_action :require_admin

  update! {collection_path}
  create! {collection_path}

end
