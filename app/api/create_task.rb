class CreateTask < Grape::API
  helpers ApiHelpers::AuthenticationHelper
  before { restrict_access_to_developers }

  desc 'End-point for the CreateTask API action'
  namespace :create_task do
    desc 'Post a new scanning task'
    params do
      requires :api_key, type: String, desc: 'API key'
      requires :title, type: String, desc: 'title for task'
      requires :author, type: String, desc: 'author and/or translator of work'
      optional :edition_details, type: String, desc: 'edition details - city, publisher, year'
      optional :extra_info, type: String, desc: 'any additional information, such as location in libraries'
      optional :full_nikkud, type: String, desc: 'is the text with full-nikkud (diacritics), e.g. poetry, children''s prose. ("true" or "false")'
    end
    post do
      api_user = APIUser.find_by_api_key(params[:api_key]) # authentication eliminated the possibility we're here without a valid key
      tasks_user = User.find_by_email(api_user.email)
      unless tasks_user.blank? || !tasks_user.admin_or_editor?
        task = Task.new(name: "#{params[:title]} / #{params[:author]}",
          kind: TaskKind.find_by_name('סריקה'), 
          source: params[:edition_details], 
          creator_id: tasks_user.id,
          full_nikkud: params[:full_nikkud])
        task.save!
        present task, with: Entities::ApiTaskEntity
        status 200
      else
        error_code = ErrorCodes::KEY_WITHOUT_WRITE_ACCESS
        error_msg = 'your API key is not allowed to change the database'
        error!({ :error_msg => error_msg, :error_code => error_code }, 403)
      end
    end
  end
end