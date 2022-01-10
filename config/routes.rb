Rails.application.routes.draw do
  resources :api_users, controller: 'xapi_users' # weird inflection problems requiring *both* APIUsersController *and* ApiUsersController to be defined. No time to deal with it.
  resources :projects
  get "report/stalled"
  get 'report/missing_metadata'
  get 'report/missing_metadata_panel/:id', controller: 'report', action: 'missing_metadata_panel'
  match 'report/hours', via: [:get, :post]
  post 'report/update_metadata'
  get "report/inactive"
  get "report/active"
  match 'report/newvols', via: [:get, :post]
  get "report/vols_notify"
  get "report/do_notify"
  get "report/index"
  match '/report' => 'report#index', via: [:get, :post]
  match '/users' => 'users#index', via: [:get]
  match '/get_last_source' => 'tasks#get_last_source', via: [:get, :post]
  match '/activate/:id' => 'passwords#edit', :as => :activate, via: [:get, :post]
  get '/users/:id/take_break', :controller => 'users', :action => 'take_break', :as => :users_take_break, :via => :get
  get '/passwords/:id/reset_password_by_editor' => 'passwords#reset_password_by_editor'
  match '/password' => 'passwords#update', :as => :password_update, :via => :put
  match '/password' => 'passwords#edit', :as => :password_edit, :via => :get
  resources :passwords, :only => [:new, :create, :edit, :update]
  match '/login' => 'user_sessions#new', :as => :login, via: [:get, :post]
  resource :user_sessions, :controller => "user_sessions"
  match '/signup' => 'users#new', :as => :signup, :controller => "users", via: [:get, :post]
  resources :users do
    resources :activation_instructions
    resources :assignment_histories
  end
  get '/users/:id/cancel_task_request', :controller => 'users', :action => 'cancel_task_request'
  match '/tasks/:id/split_task', controller: 'admin/tasks', action: 'split_task', as: 'split_task', via: [:get, :post]
  get '/tasks/:id/make_comments_editor_only', :controller => 'tasks', :action => 'make_comments_editor_only'
  get '/tasks/:id/download_pdf', :controller => 'tasks', :action => 'download_pdf', as: 'task_download_pdf'
  match '/tick_file/:id' => 'documents#tick_file', :via => :get

  resource :profile, :controller => "users"
  match '/profiles/:id' => 'users#show', :as => :profiles, :public_profile => true, via: [:get, :post]
  match '/' => 'welcome#index', via: :get
  match '/byebye' => 'welcome#byebye', via: [:get, :post]
  #resources :pages, :only => [:show]
  resources :properties
  match '/dashboard' => 'dashboards#index', :via => :get, :as => :dashboard
  resources :volunteer_requests
  namespace :admin do
    resources :tasks, :only => [:index, :new, :create, :edit, :update, :destroy]
    resources :task_kinds, :only => [:create, :new, :index, :destroy]
    resources :volunteer_kinds, :only => [:create, :new, :index, :destroy]
  end
  get '/admin/changes', :controller => 'admin/tasks', :action => 'changes'

  resources :tasks do
    resources :documents
    resource :assignment
    resources :comments
  end

  resources :task_requests
  resources :site_notices
  match "/restart", :controller => "restart", :action => "restart", :via => :post
  mount API => '/'

end
