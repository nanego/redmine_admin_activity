require 'spec_helper'

if Redmine::Plugin.installed?(:redmine_organizations)
  describe OrganizationsController, type: :controller do
    render_views

    fixtures :projects, :users, :organizations

    include Redmine::I18n

    before do
      @controller = OrganizationsController.new
      @request = ActionDispatch::TestRequest.create
      @response = ActionDispatch::TestResponse.new
      User.current = nil
      @request.session[:user_id] = 1
    end

    describe "POST create" do
      it "logs change on JournalSetting" do
        post :create, :params => { :organization => { :name => "Org child", :parent_id => 1} }

        expect(JournalSetting).to_not be_nil
        expect(JournalSetting.last.value_changes).to include({ "name" => [nil, "Org child"] })
        expect(JournalSetting.last.value_changes).to include({ "name_with_parents" => [nil, "Org A/Org child"] })
        expect(JournalSetting.last).to have_attributes(:journalized_type => "Organization")
        expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "create")
        expect(JournalSetting.last).to have_attributes(:journalized_id => Organization.last.id)
      end
    end

    describe "DELETE destroy" do
      it "logs change on JournalSetting when we delete a child organization" do
        org = Organization.create(:name => 'Org child', :parent_id => 1 )
        id = Organization.last.id
        delete :destroy, :params => { :id => id, :confirm => true }

        expect(JournalSetting).to_not be_nil
        expect(JournalSetting.last.value_changes).to include({ "name" => [org.name, nil] })
        expect(JournalSetting.last.value_changes).to include({ "name_with_parents" => [org.fullname, nil] })
        expect(JournalSetting.last).to have_attributes(:journalized_type => "Organization")
        expect(JournalSetting.last).to have_attributes(:journalized_id => id)
        expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "destroy")
      end

      it "logs change on JournalSetting when we delete a parent organization" do
        org_array = []

        4.times do |i|
          org_array << Organization.create(:name => "Org child#{i}", :parent_id => i == 0 ? nil : Organization.last.id)
        end

        # delete the parent organization
        parent_id = Organization.last(4)[0].id
        delete :destroy, :params => { :id => parent_id, :confirm => true }

        4.times do |i|
          expect(JournalSetting.last(4)[i].value_changes).to include({ "name" => [org_array[i].name, nil] })
          expect(JournalSetting.last(4)[i].value_changes).to include({ "name_with_parents" => [org_array[i].fullname, nil] })
          expect(JournalSetting.last(4)[i]).to have_attributes(:journalized_type => "Organization")
          expect(JournalSetting.last(4)[i]).to have_attributes(:journalized_id => org_array[i].id)
          expect(JournalSetting.last(4)[i]).to have_attributes(:journalized_entry_type => "destroy")
        end
      end

    end

    describe "patch Update" do
      it "logs change on JournalSetting when we update a organization" do
        org = Organization.last
        expect do
          patch :update, :params => {
            :id => org.id,
            :organization => {
              :name => "new_name",
              :description => "new_des",
              :parent_id => Organization.find(2).id,
              :mail => "test@test.com",
              :direction => true,
            }
          }
        end.to change { JournalSetting.count }.by(1)

        expect(JournalSetting.last.value_changes).to include({ "name" => [org.name, "new_name"] })
        expect(JournalSetting.last.value_changes).to include({ "description" => [org.description, "new_des"] })
        expect(JournalSetting.last.value_changes).to include({ "parent_id" => [org.parent.id, Organization.find(2).id] })
        expect(JournalSetting.last.value_changes).to include({ "direction" => [nil, true] })
        expect(JournalSetting.last.value_changes).to include({ "mail" => [org.mail, "test@test.com"] })
        expect(JournalSetting.last).to have_attributes(:journalized_type => "Organization")
        expect(JournalSetting.last).to have_attributes(:journalized_id => org.id)
        expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "update")

      end
    end
  end
end