require "rails_helper"

describe ProjectsHelper, :type => :controller do

  render_views

  fixtures :users, :roles, :projects, :members,
           :member_roles, :enabled_modules, :issues

  before do
    @controller = ProjectsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session = ActionController::TestSession.new
    @request.session[:user_id] = 3
  end

  it "should display project_settings_tabs_with_admin_activity" do

    project = Project.find(1)
    role = User.find(3).roles_for_project(project).first

    role.permissions = []
    role.save
    get :settings, :params => {
      :id => project.id
    }
    assert_response 403

    role.add_permission! :see_project_activity, :manage_repository

    get :settings, :params => {
      :id => project.id
    }
    assert_response :success
    assert_select "a[href='/projects/1/settings/admin_activity']"

  end
end
