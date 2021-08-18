class CreateTask < Grape::API
  helpers ApiHelpers::AuthenticationHelper
  before { restrict_access_to_developers }

  format :json
  desc 'End-point for the CreateTask API action'
  namespace :create_task do
    desc 'Post a new scanning task'
    params do
      requires :api_key, type: String, desc: 'API key'
      requires :title, type: String, desc: 'title for task'
      requires :author, type: String, desc: 'author and/or translator of work'
      requires :creator_id, type: Integer, desc: 'id of TASKS user to set as task creator'
      optional :edition_details, type: String, desc: 'edition details - city, publisher, year'
      optional :extra_info, type: String, desc: 'any additional information, such as location in libraries'
      optional :full_nikkud, type: String, desc: 'is the text with full-nikkud (diacritics), e.g. poetry, children''s prose. ("true" or "false")'
    end
    post do
      task = Task.new(name: "#{params[:title]} / #{params[:author]}",
        kind: TaskKind.find_by_name('סריקה'), 
        source: params[:edition_details], 
        creator_id: params[:creator_id],
        full_nikkud: params[:full_nikkud])
      task.save!
      present task, with: Entities::ApiTaskEntity
      status 200
    end
  end
end