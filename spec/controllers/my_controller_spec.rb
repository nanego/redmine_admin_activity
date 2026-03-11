require 'rails_helper'

describe MyController, type: :controller do

  fixtures :users, :email_addresses

  include Redmine::I18n

  before do
    @controller = MyController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session = ActionController::TestSession.new
    @request.session[:user_id] = 2 # jsmith (non-admin)
  end

  describe "PUT account" do
    it "logs name and mail change in JournalSetting and JournalDetail" do
      user = User.find(2)
      user.update_attribute :mail, "old_mail@example.net"

      expect do
        put :account, :params => { :user => { :firstname => 'Nouveau', :lastname => 'Nom', :mail => 'new_mail@example.net' } }
      end.to change(Journal, :count).by(1)
         .and change(JournalDetail, :count).by(3)
         .and change(JournalSetting.where(journalized_entry_type: "update"), :count).by(1)

      expect(Journal.last.journalized_type).to eq("Principal")
      expect(Journal.last.journalized_id).to eq(user.id)

      details = JournalDetail.last(3)
      expect(details.map(&:prop_key)).to include("firstname", "lastname", "mails")

      js = JournalSetting.where(journalized_entry_type: "update").last
      expect(js.journalized_type).to eq("Principal")
      expect(js.value_changes).to include("firstname", "lastname", "mails")
    end

    it "does not log anything on GET request" do
      expect do
        get :account
      end.not_to change(JournalSetting, :count)
      expect { get :account }.not_to change(Journal, :count)
    end
  end

  describe "POST password" do
    # jsmith password fixture is 'jsmith'
    it "logs masked password change in JournalSetting and JournalDetail" do
      expect do
        post :password, :params => {
          :password => 'jsmith',
          :new_password => 'newpassword123!',
          :new_password_confirmation => 'newpassword123!'
        }
      end.to change(JournalSetting.where(journalized_entry_type: "update"), :count).by(1)
         .and change(JournalDetail, :count).by(1)

      js = JournalSetting.where(journalized_entry_type: "update").last
      expect(js.journalized_type).to eq("Principal")
      expect(js.journalized_id).to eq(2)
      expect(js.value_changes.keys).to include("hashed_password")
      expect(js.value_changes["hashed_password"]).to eq([nil, nil])

      detail = JournalDetail.last
      expect(detail.prop_key).to eq("hashed_password")
      expect(detail.old_value).to be_nil
      expect(detail.value).to be_nil
    end

    it "does not log anything on GET request" do
      expect do
        get :password
      end.not_to change(JournalSetting, :count)
      expect { get :password }.not_to change(Journal, :count)
    end
  end
end
