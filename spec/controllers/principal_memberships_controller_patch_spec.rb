require 'spec_helper'

describe PrincipalMembershipsController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  if Redmine::Plugin.installed?(:redmine_limited_visibility)
    fixtures :functions
  end

  include Redmine::I18n

  before do
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:project1) { projects(:projects_001) }
  let(:project2) { projects(:projects_002) }
  let(:admin) { users(:users_001) }
  let(:user) { users(:users_009) } # User Misc
  let(:member) { members(:members_001) } # User 2 (John Smith) member of Project 1 with 'Manager' role
  let(:role) { roles(:roles_002) } # Developer

  if Redmine::Plugin.installed?(:redmine_limited_visibility)
    let(:function) { functions(:functions_001) }
  end

  describe "POST /" do
    it "adds a member to projects" do
      post :create, params: { user_id: user.id, membership: { project_ids: [project1.id, project2.id], role_ids: [role.id] } }

      expect(response).to redirect_to('http://test.host/users/9/edit?tab=memberships')
      expect(project1.journals).to_not be_nil
      expect(project2.journals).to_not be_nil

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        expect(project1.journals.last.details.last).to have_attributes(:value => "{\"name\":\"User Misc\",\"roles\":[\"Developer\"],\"functions\":[]}", :old_value => nil)
        expect(project2.journals.last.details.last).to have_attributes(:value => "{\"name\":\"User Misc\",\"roles\":[\"Developer\"],\"functions\":[]}", :old_value => nil)
      else
        expect(project1.journals.last.details.last).to have_attributes(:value => "{\"name\":\"User Misc\",\"roles\":[\"Developer\"]}", :old_value => nil)
        expect(project2.journals.last.details.last).to have_attributes(:value => "{\"name\":\"User Misc\",\"roles\":[\"Developer\"]}", :old_value => nil)
      end
    end

    it "add logs on JournalDetail when adds a member to projects" do

      expect do
        post :create, params: { user_id: user.id, membership: { project_ids: [project1.id, project2.id], role_ids: [role.id] } }
      end.to change { Journal.count }.by(4)
                                     .and change { JournalDetail.count }.by(4)

      expect(Journal.last(4)[1].journalized_type).to eq("Principal")
      expect(Journal.last(4)[1].journalized_id).to eq(user.id)
      expect(Journal.last(4)[3].journalized_type).to eq("Principal")
      expect(Journal.last(4)[3].journalized_id).to eq(user.id)

      expect(JournalDetail.last(4)[1].property).to eq("associations")
      expect(JournalDetail.last(4)[1].prop_key).to eq("projects")
      expect(JournalDetail.last(4)[1].old_value).to be_nil
      expect(JournalDetail.last(4)[1].value).to eq(project1.id.to_s)

      expect(JournalDetail.last(4)[3].property).to eq("associations")
      expect(JournalDetail.last(4)[3].prop_key).to eq("projects")
      expect(JournalDetail.last(4)[3].old_value).to be_nil
      expect(JournalDetail.last(4)[3].value).to eq(project2.id.to_s)

    end
  end

  describe "DELETE /:id" do
    it "removes a member" do
      project1.update(functions: [function]) if Redmine::Plugin.installed?(:redmine_limited_visibility)
      member = Member.new(:project => project1, :user => user)
      member.set_editable_role_ids([roles(:roles_001).id], admin)
      member.set_functional_roles([function.id]) if Redmine::Plugin.installed?(:redmine_limited_visibility)
      member.save!

      delete :destroy, params: { user_id: member.principal.id, id: member.id }
      expect(response).to redirect_to('http://test.host/users/9/edit?tab=memberships')
      expect(project1.journals).to_not be_nil

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        expect(project1.journals.last.details.last).to have_attributes(:value => nil, :old_value => "{\"name\":\"User Misc\",\"roles\":[\"Manager\"],\"functions\":[\"function1\"]}")
      else
        expect(project1.journals.last.details.last).to have_attributes(:value => nil, :old_value => "{\"name\":\"User Misc\",\"roles\":[\"Manager\"]}")
      end
    end
  end
end
