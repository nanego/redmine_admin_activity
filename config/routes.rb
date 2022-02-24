RedmineApp::Application.routes.draw do
  get 'users/:id/history', :controller => 'users', :action => 'history', :via => :get, :as => :history_user
end

