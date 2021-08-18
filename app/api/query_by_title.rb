class QueryByTitle < Grape::API
  helpers ApiHelpers::AuthenticationHelper
  before { restrict_access_to_developers }

  format :json
  desc 'End-point for the QueryByTitle API action'
  namespace :query_by_title do
    desc 'Query by task title'
    params do
      requires :api_key, type: String, desc: 'API key'
      requires :title, type: String, desc: 'title to substring match'
    end
    get do
      tasks = Task.where("name like ?","%#{params[:title]}")
      present tasks, with: Entities::ApiTaskEntity
      status 200
    end
  end
end