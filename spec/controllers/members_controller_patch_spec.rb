require 'spec_helper'

describe MembersController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    @controller = described_class.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:project) { projects(:projects_001) }
  let(:user)    { users(:users_009) } # User Misc
  let(:member)  { members(:members_001) } # User 2 (John Smith) member of Project 1 with 'Manager' role
  let(:role)    { roles(:roles_002) } # Developer

  describe "POST /" do
    it "adds a new member" do
      post :create, params: { project_id: project.id, membership: { user_ids: [user.id], role_ids: [role.id] } }
      expect(response).to redirect_to('/projects/ecookbook/settings/members')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "{\"name\":\"User Misc\",\"roles\":[\"Developer\"]}", :old_value => nil)
    end
  end

  describe "PATCH /:id" do
    it "replaces current role by another" do
      patch :update, params: { id: member.id, membership: { role_ids: [role.id] } }
      expect(response).to redirect_to('/projects/ecookbook/settings/members')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "{\"name\":\"John Smith\",\"roles\":[\"Developer\"]}", :old_value => "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}")
    end

    it "adds a role to a member" do
      patch :update, params: { id: member.id, membership: { role_ids: member.roles.map(&:id) + [role.id] } }
      expect(response).to redirect_to('/projects/ecookbook/settings/members')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "{\"name\":\"John Smith\",\"roles\":[\"Manager\",\"Developer\"]}", :old_value => "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}")
    end
  end

  describe "DELETE /:id" do
    it "removes a member" do
      delete :destroy, params: { id: member.id }
      expect(response).to redirect_to('/projects/ecookbook/settings/members')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}")
    end
  end
end
