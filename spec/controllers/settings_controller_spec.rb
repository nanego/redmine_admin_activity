require 'spec_helper'

describe SettingsController, type: :controller do

  render_views

  include Redmine::I18n

  before do
    @controller = SettingsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions are hard
  end
end
