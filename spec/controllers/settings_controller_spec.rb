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
      post :edit, params: { "settings" => { "app_title" => "Redmine test" } }

      expect(response).to redirect_to('/settings')
      expect(JournalSetting.all).to be_present
      expect(JournalSetting.last).to have_attributes(:value_changes => { "app_title" => ["Redmine", "Redmine test"] })
    end
  end

  describe "Pagination of user history" do
    before do
      session[:per_page] = 3
    end

    it "check the number of elements by page" do
      Setting[:app_title] = "Redmine"
      post :edit, params: { "settings" => { "app_title" => "Redmine test 1" } }
      post :edit, params: { "settings" => { "app_title" => "Redmine test 2" } }
      post :edit, params: { "settings" => { "app_title" => "Redmine test 3" } }
      post :edit, params: { "settings" => { "app_title" => "Redmine test 4" } }
      post :edit, params: { "settings" => { "app_title" => "Redmine test 5" } }
      
      # Get all journals of the first page
      get :index, :params => { :tab => "admin_activity", page: 1}
      first_page = assigns(:journals)

      # Get all journals of the second page
      get :index, :params => { :tab => "admin_activity", page: 2}
      second_page = assigns(:journals)

      # Tests
      expect(first_page.count).to eq(3)
      expect(second_page.count).to eq(2)
      expect(first_page.first.id).to be > second_page.first.id      
    end
  end

end
