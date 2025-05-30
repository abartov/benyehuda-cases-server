Rails.application.routes.draw do
  resources :api_users, controller: 'xapi_users' # weird inflection problems requiring *both* APIUsersController *and* ApiUsersController to be defined. No time to deal with it.
  resources :projects
  resources :teams do
    post 'mass_message', on: :member
  end
  resources :team_memberships do
    # remove a user from a team
    delete 'leave', on: :member
  end
  resources :task_teams
  get 'autocomplete_task_title' => 'tasks#autocomplete_task_name', as: 'autocomplete_task_title'
  get 'report/stalled'
  get 'report/missing_metadata'
  get 'report/few_tasks_left'
  get 'report/missing_metadata_panel/:id', controller: 'report', action: 'missing_metadata_panel'
  match 'report/hours', via: %i[get post]
  post 'report/update_metadata'
  get 'report/inactive'
  get 'report/active'
  match 'report/newvols', via: %i[get post]
  get 'report/vols_notify'
  get 'report/do_notify'
  get 'report/index'
  match '/report' => 'report#index', via: %i[get post]
  match '/users' => 'users#index', via: [:get]
  match '/get_last_source' => 'tasks#get_last_source', via: %i[get post]
  match '/activate/:id' => 'passwords#edit', :as => :activate, via: %i[get post]
  get '/users/:id/take_break', controller: 'users', action: 'take_break', as: :users_take_break, via: :get
  get '/passwords/:id/reset_password_by_editor' => 'passwords#reset_password_by_editor'
  match '/password' => 'passwords#update', :as => :password_update, :via => :put
  match '/password' => 'passwords#edit', :as => :password_edit, :via => :get
  resources :passwords, only: %i[new create edit update]
  match '/login' => 'user_sessions#new', :as => :login, via: %i[get post]
  resource :user_sessions, controller: 'user_sessions'
  match '/signup' => 'users#new', :as => :signup, :controller => 'users', via: %i[get post]
  resources :users do
    resources :activation_instructions
    resources :assignment_histories
  end
  get '/users/:id/cancel_task_request', controller: 'users', action: 'cancel_task_request'
  match '/tasks/:id/split_task', controller: 'admin/tasks', action: 'split_task', as: 'split_task', via: %i[get post]
  match '/tasks/:id/classify_scans', controller: 'admin/tasks', action: 'classify_scans', as: 'classify_scans',
                                     via: %i[get post]
  get '/tasks/:id/make_comments_editor_only', controller: 'tasks', action: 'make_comments_editor_only'
  get '/tasks/:id/download_pdf', controller: 'tasks', action: 'download_pdf', as: 'task_download_pdf'
  get '/tasks/:id/start_ingestion', controller: 'admin/tasks', action: 'start_ingestion', as: 'task_start_ingestion'
  get '/tasks/:id/workaround_document/:document', controller: 'documents', action: 'workaround_download',
                                                  as: 'workaround_task_document'

  match '/tick_file/:id' => 'documents#tick_file', :via => :get

  resource :profile, controller: 'users'
  match '/profiles/:id' => 'users#show', :as => :profiles, :public_profile => true, via: %i[get post]
  match '/' => 'welcome#index', via: :get
  match '/byebye' => 'welcome#byebye', via: %i[get post]
  # resources :pages, :only => [:show]
  resources :properties
  match '/dashboard' => 'dashboards#index', :via => :get, :as => :dashboard
  resources :volunteer_requests
  namespace :admin do
    resources :tasks, only: %i[index new create edit update destroy]
    resources :task_kinds, only: %i[create new index destroy]
    resources :volunteer_kinds, only: %i[create new index destroy]
  end
  get '/admin/changes', controller: 'admin/tasks', action: 'changes'

  resources :tasks do
    resources :documents
    resource :assignment
    resources :comments
  end

  resources :task_requests
  resources :site_notices
  match '/restart', controller: 'restart', action: 'restart', via: :post
  mount API => '/'
end
