require 'spec_helper'

describe UsersController, type: :controller do
  
  render_views

  fixtures :users

  include Redmine::I18n

  before do
    @controller = UsersController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions admin
  end

  describe "POST create" do
    it "logs change on JournalSetting" do
      post :create, :params => {
        :user => {
          :login => 'newuser',
          :firstname => 'new',
          :lastname => 'user',
          :mail => 'newuser@example.net',
          :generate_password => '1',
        }
      }
      user = User.last

      expect(response).to redirect_to("/users/#{user.id}/edit")
      expect(JournalSetting.all).to_not be_nil
      expect(JournalSetting.all.last.value_changes).to include("id" => [nil, user.id])
      expect(JournalSetting.all.last.value_changes).to include("login" => ["", "newuser"])
      expect(JournalSetting.all.last.value_changes).to include("firstname" => ["", "new"])
      expect(JournalSetting.all.last.value_changes).to include("lastname" => ["", "user"])
      expect(JournalSetting.all.last.value_changes).to include("type" => [nil, "User"])
      expect(JournalSetting.all.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.all.last).to have_attributes(:journalized_entry_type => "create")
    end
  end

  describe "POST update" do
    it "add logs on JournalSetting When locking the account of a user" do
      patch :update, :params => { :id => 7, :user => {:status => Principal::STATUS_LOCKED, :mail => 'newuser@example.net'} }
      
      expect(JournalSetting.all).to_not be_nil
      expect(JournalSetting.all.last.value_changes).to include({ "status" => [Principal::STATUS_ACTIVE, Principal::STATUS_LOCKED] })
      expect(JournalSetting.all.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.all.last).to have_attributes(:journalized_entry_type => "lock")
    end

    it "add logs on JournalSetting When unlocking the account of a user" do
      user = User.find(7)
      user.update_attribute :status, Principal::STATUS_LOCKED
      patch :update, :params => { :id => 7, :user => {:status => Principal::STATUS_ACTIVE, :mail => 'newuser@example.net'} }
      
      expect(JournalSetting.all).to_not be_nil
      expect(JournalSetting.all.last.value_changes).to include({ "status" => [Principal::STATUS_LOCKED, Principal::STATUS_ACTIVE] })
      expect(JournalSetting.all.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.all.last).to have_attributes(:journalized_entry_type => "unlock")
    end

    it "add logs on JournalSetting When activation the account of a user" do
      user = User.find(7)
      user.update_attribute :status, Principal::STATUS_REGISTERED
      patch :update, :params => { :id => 7, :user => {:status => Principal::STATUS_ACTIVE, :mail => 'newuser@example.net'} }
      
      expect(JournalSetting.all).to_not be_nil
      expect(JournalSetting.all.last.value_changes).to include({ "status" => [Principal::STATUS_REGISTERED, Principal::STATUS_ACTIVE] })
      expect(JournalSetting.all.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.all.last).to have_attributes(:journalized_entry_type => "active")
    end

    it "add logs on JournalDetail when changing his attributes" do
      user = User.find(5)
      user.update_attribute :status, Principal::STATUS_LOCKED
      user.update_attribute :mail, "old_mail@example.net"
      # set requested attribute
      if Redmine::Plugin.installed?(:redmine_scn)
        user.update_attribute :issue_display_mode, "by_priority"
      end

      expect do
        patch :update, :params => { :id => user.id,
                                    :user => {:login => 'test',
                                    :status => Principal::STATUS_ACTIVE,
                                    :mail => 'new_mail@example.net'} }

      end.to change(Journal, :count).by(1)
         .and change(JournalDetail, :count).by(3)

      expect(Journal.last.journalized_type).to eq("Principal")
      expect(Journal.last.journalized_id).to eq(user.id)
      expect(JournalDetail.last.property).to eq("attr")
      expect(JournalDetail.last(3)[0].prop_key).to eq("login")
      expect(JournalDetail.last.prop_key).to eq("mails")
      expect(JournalDetail.last.old_value).to eq(["old_mail@example.net"].to_s)
      expect(JournalDetail.last.value).to eq(user.mails.to_s)
    end

    if Redmine::Plugin.installed?(:redmine_organizations)
      it "add logs on JournalDetail when changing his organization" do
        user = User.find(5)
        org_id = Organization.find(1).id
        # set requested attribute
        user.update_attribute :mail, "old_mail@example.net"
        if Redmine::Plugin.installed?(:redmine_scn)
          user.update_attribute :issue_display_mode, "by_priority"
        end

        expect do
          patch :update,
                :params => { :id => user.id, :user => { :organization_id => org_id } }

        end.to change { Journal.count }.by(1)
           .and change(JournalDetail, :count).by(1)

        expect(Journal.last.journalized_type).to eq("Principal")
        expect(Journal.last.journalized_id).to eq(user.id)
        expect(JournalDetail.last.property).to eq("attr")
        expect(JournalDetail.last.prop_key).to eq("organization_id")
        expect(JournalDetail.last.old_value).to be_nil
        expect(JournalDetail.last.value).to eq(org_id.to_s)

      end
    end

  end

  describe "DELETE destroy" do
    it "logs change on JournalSetting" do
      delete :destroy, :params => { :id => 7, :confirm => "someone" }
      
      expect(response).to redirect_to('/users')
      expect(JournalSetting.all).to_not be_nil
      expect(JournalSetting.all.last.value_changes).to include({ "login" => ["someone", nil] })
      expect(JournalSetting.all.last.value_changes).to include({ "firstname" => ["Some", nil] })
      expect(JournalSetting.all.last.value_changes).to include({ "lastname" => ["One", nil] })
      expect(JournalSetting.all.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.all.last).to have_attributes(:journalized_entry_type => "destroy")
    end  
  end
  describe "permission of user's history" do
    it "Should not allow access to history when user with incorrect permission" do
      @request.session[:user_id] = 5
      get :history, params: { id: 1 }
      expect(response).not_to have_http_status(:success)

    end
    it "Should allow access to history when user with correct permission" do
      get :history, :params => { id: 7 }
      expect(response).to have_http_status(:success)
    end
  end
end
