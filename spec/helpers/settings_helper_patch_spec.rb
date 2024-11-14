require "rails_helper"

describe SettingsHelper, :type => :controller do

  render_views

  before do
    @controller = SettingsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session = ActionController::TestSession.new
    @request.session[:user_id] = 1
  end

  it "should display administration_settings_tabs_with_admin_activity" do
    get :index

    assert_response :success
    assert_select "a[href='/settings?tab=admin_activity']"
  end

  it "should not display administration_settings_tabs_with_admin_activity" do
    @request.session[:user_id] = 2

    get :index
    assert_response 403
  end
end
