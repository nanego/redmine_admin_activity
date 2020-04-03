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

  describe "POST edit" do
    it "logs change on module" do
      Setting[:app_title] = "Redmine"
      post :edit, params: { "settings"=> { "app_title" => "Redmine test" } }

      expect(response).to redirect_to('/settings')
      expect(JournalSetting.all).to_not be_nil
      expect(JournalSetting.all.last).to have_attributes(:value_changes => {"app_title" => ["Redmine","Redmine test"]})
    end
  end
end
