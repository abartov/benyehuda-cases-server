CasesServer::Application.routes.draw do
  get "report/stalled"
  get "report/inactive"
  get "report/active"
  get "report/newvols"
  get "report/vols_notify"
  get "report/do_notify"
  get "report/index"
  match '/report' => 'report#index'

  match '/activate/:id' => 'passwords#edit', :as => :activate
  match '/password' => 'passwords#update', :as => :password_update, :via => :put
  match '/password' => 'passwords#edit', :as => :password_edit, :via => :get
  resources :passwords, :only => [:new, :create, :edit, :update]
  match '/login' => 'user_session#new', :as => :login
  resource :user_session, :controller => "user_session"
  match '/signup' => 'users#new', :as => :signup, :controller => "users"
  resources :users do
    resources :activation_instructions
    resources :assignment_histories
  end
  get '/users/:id/cancel_task_request', :controller => 'users', :action => 'cancel_task_request'
  get '/tasks/:id/make_comments_editor_only', :controller => 'tasks', :action => 'make_comments_editor_only'

  resource :profile, :controller => "users"
  match '/profiles/:id' => 'users#show', :as => :profiles, :public_profile => true
  match '/' => 'welcome#index'
  match '/byebye' => 'welcome#byebye'
  resources :pages, :only => [:show]
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
end
