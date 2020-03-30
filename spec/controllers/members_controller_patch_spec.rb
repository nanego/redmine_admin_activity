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
  let(:user)    { users(:users_009) }
  let(:member)  { members(:members_001) }
  let(:role)    { roles(:roles_002) }

  describe "POST /" do
    before { post :create, params: { project_id: project.id, membership: { user_ids: [user.id], roles_ids: [role.id] } } }

    it { expect(response).to redirect_to('/projects/ecookbook/settings/members') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "{\"name\":\"User Misc\",\"roles\":[]}", :old_value => nil) }
  end

  describe "PATCH /:id" do
    before { patch :update, params: { id: member.id, membership: { roles_ids: [role.id] } } }

    it { expect(response).to redirect_to('/projects/ecookbook/settings/members') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "{\"name\":\"John Smith\",\"roles\":[]}", :old_value => "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}") }
  end

  describe "DELETE /:id" do
    before { delete :destroy, params: { id: member.id } }

    it { expect(response).to redirect_to('/projects/ecookbook/settings/members') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}") }
  end
end
