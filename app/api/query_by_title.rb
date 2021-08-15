class QueryByTitle < Grape::API
  format :json
  desc 'End-points for the QueryByTitle API action'
  namespace :query_by_title do
    desc 'Query by task title'
    params do
      requires :token, type: String, desc: 'API token from login action'
      requires :title, type: String, desc: 'title to substring match'
    end
    get do
    end
  end
end