require 'rails_helper'

describe UsersController, type: :controller do

  render_views

  fixtures :users, :email_addresses

  include Redmine::I18n

  before do
    @controller = UsersController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session = ActionController::TestSession.new
    @request.session[:user_id] = 1 # permissions admin
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
      new_user = User.last

      expect(response).to redirect_to("/users/#{new_user.id}/edit")

      expect(JournalSetting.all).to_not be_empty

      last_journal_setting = JournalSetting.last

      expect(last_journal_setting.value_changes).to include("id" => [nil, new_user.id])
      expect(last_journal_setting.value_changes).to include("login" => ["", "newuser"])
      expect(last_journal_setting.value_changes).to include("firstname" => ["", "new"])
      expect(last_journal_setting.value_changes).to include("lastname" => ["", "user"])
      expect(last_journal_setting.value_changes).to include("type" => [nil, "User"])
      expect(last_journal_setting).to have_attributes(:journalized_type => "Principal")
      expect(last_journal_setting).to have_attributes(:journalized_entry_type => "create")

      last_journal_detail = JournalDetail.last

      expect(last_journal_detail.property).to eq('creation')
      expect(last_journal_detail.prop_key).to eq('creation')
      expect(last_journal_detail.value).to eq(User::USER_MANUAL_CREATION)
      expect(Journal.last.journalized_id).to eq(new_user.id)
    end
  end

  describe "POST update" do
    it "add logs on JournalSetting When locking the account of a user" do
      patch :update, :params => { :id => 7, :user => { :status => Principal::STATUS_LOCKED, :mail => 'newuser@example.net' } }
      expect(JournalSetting.all).to_not be_empty
      expect(JournalSetting.last.value_changes).to include({ "status" => [Principal::STATUS_ACTIVE, Principal::STATUS_LOCKED] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "lock")
    end

    it "add logs on JournalSetting When unlocking the account of a user" do
      user = User.find(7)
      user.update_attribute :status, Principal::STATUS_LOCKED
      patch :update, :params => { :id => 7, :user => { :status => Principal::STATUS_ACTIVE, :mail => 'newuser@example.net' } }

      expect(JournalSetting.all).to_not be_empty
      expect(JournalSetting.last.value_changes).to include({ "status" => [Principal::STATUS_LOCKED, Principal::STATUS_ACTIVE] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "unlock")
    end

    it "add logs on JournalSetting When activation the account of a user" do
      user = User.find(7)
      user.update_attribute :status, Principal::STATUS_REGISTERED
      patch :update, :params => { :id => 7, :user => { :status => Principal::STATUS_ACTIVE, :mail => 'newuser@example.net' } }

      expect(JournalSetting.all).to_not be_empty
      expect(JournalSetting.last.value_changes).to include({ "status" => [Principal::STATUS_REGISTERED, Principal::STATUS_ACTIVE] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "active")
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
                                    :user => { :login => 'test',
                                               :status => Principal::STATUS_ACTIVE,
                                               :mail => 'new_mail@example.net' } }

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
        org = Organization.find(1)
        user.update_attribute :mail, "old_mail@example.net"
        if Redmine::Plugin.installed?(:redmine_scn)
          user.update_attribute :issue_display_mode, "by_priority"
        end

        expect do
          patch :update,
                :params => { :id => user.id, :user => { :organization_id => org.id } }
        end.to change { Journal.count }.by(1)
                                       .and change(JournalDetail, :count).by(1)

        expect(Journal.last.journalized_type).to eq("Principal")
        expect(Journal.last.journalized_id).to eq(user.id)
        expect(JournalDetail.last.property).to eq("attr")
        expect(JournalDetail.last.prop_key).to eq("organization")
        expect(JournalDetail.last.old_value).to be_nil
        expect(JournalDetail.last.value).to eq(org.to_s)

      end
    end

    it "creates a JournalSetting update and a JournalDetail when changing admin rights" do
      user = User.find(7)
      # When redmine_sudo is installed, sudoer is the persistent rights flag (admin is a toggle).
      # The JournalSetting and JournalDetail track sudoer (or admin when sudo is not installed).
      tracked_field = Redmine::Plugin.installed?(:redmine_sudo) ? 'sudoer' : 'admin'

      expect do
        patch :update, :params => { :id => user.id, :user => { :admin => '1' } }
      end.to change(JournalSetting.where(journalized_entry_type: "update"), :count).by(1)
         .and change(JournalDetail, :count).by(1)

      js = JournalSetting.where(journalized_entry_type: "update").last
      expect(js.journalized_type).to eq("Principal")
      expect(js.value_changes).to include(tracked_field => [false, true])

      detail = JournalDetail.last
      expect(detail.property).to eq("attr")
      expect(detail.prop_key).to eq(tracked_field)
      expect(detail.old_value).to eq("f").or eq("0").or eq("false")
      expect(detail.value).to eq("t").or eq("1").or eq("true")
    end

    it "creates a JournalSetting update with masked password when changing password" do
      user = User.find(7)
      expect do
        patch :update, :params => { :id => user.id,
                                    :user => { :password => 'newpassword123!',
                                               :password_confirmation => 'newpassword123!' } }
      end.to change(JournalSetting.where(journalized_entry_type: "update"), :count).by(1)
         .and change(JournalDetail, :count).by(1)

      js = JournalSetting.where(journalized_entry_type: "update").last
      expect(js.journalized_entry_type).to eq("update")
      expect(js.value_changes.keys).to include("hashed_password")
      expect(js.value_changes["hashed_password"]).to eq([nil, nil])

      detail = JournalDetail.last
      expect(detail.prop_key).to eq("hashed_password")
      expect(detail.old_value).to be_nil
      expect(detail.value).to be_nil
    end

    it "does not create a JournalSetting update when only status changes" do
      user = User.find(7)
      patch :update, :params => { :id => user.id, :user => { :status => Principal::STATUS_LOCKED } }

      expect(JournalSetting.where(journalized_entry_type: "update").count).to eq(0)
      expect(JournalSetting.last.journalized_entry_type).to eq("lock")
    end

  end

  describe "DELETE destroy" do
    it "logs change on JournalSetting" do
      delete :destroy, :params => { :id => 7, :confirm => "someone" }

      expect(response).to redirect_to('/users')
      expect(JournalSetting.all).to_not be_empty
      expect(JournalSetting.last.value_changes).to include({ "login" => ["someone", nil] })
      expect(JournalSetting.last.value_changes).to include({ "firstname" => ["Some", nil] })
      expect(JournalSetting.last.value_changes).to include({ "lastname" => ["One", nil] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Principal")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "destroy")
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

  describe "Should show the history link" do
    it "Should show the link in profile page" do
      get :show, :params => { id: 1 }
      expect(response).to have_http_status(:success)
      expect(response.body).to have_css("a[class='icon icon-time']")
    end
    it "Should show the link in profile page" do
      get :edit, :params => { id: 1 }
      expect(response).to have_http_status(:success)
      expect(response.body).to have_css("a[class='icon icon-time']")
    end
  end

  describe "Pagination of user history" do
    before do
      session[:per_page] = 3
    end

    it "check the number of elements by page" do
      user = User.find(2)
      5.times do |index|
        patch :update, :params => { :id => user.id, :user => { :mail => "test#{index}@example.net" } }
      end
      # Get all journals of the first page
      get :history, :params => { :id => user.id, page: 1 }
      first_page = assigns(:journals)

      # Get all journals of the second page
      get :history, :params => { :id => user.id, page: 2 }
      second_page = assigns(:journals)

      # Tests
      expect(first_page.count).to eq(3)
      expect(second_page.count).to eq(2)
      expect(first_page.first.id).to be > second_page.first.id
    end
  end
end
