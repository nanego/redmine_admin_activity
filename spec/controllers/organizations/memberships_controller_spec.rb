require 'spec_helper'

if Redmine::Plugin.installed?(:redmine_organizations)
  describe Organizations::MembershipsController, type: :controller do
    render_views

    fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
             :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
             :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
             :time_entries, :journals, :journal_details, :queries, :repositories, :changesets, :organizations

    if Redmine::Plugin.installed?(:redmine_limited_visibility)
      fixtures :functions
      let(:function) { functions(:functions_003) }
    end

    let(:organization) { organizations(:organization_001) }
    let(:project) { projects(:projects_001) }
    let(:role) { roles(:roles_001) }
    let(:new_role) { roles(:roles_002) }
    let(:user) { users(:users_002) } # member of project
    let(:new_user) { users(:users_004) } # not member of project

    before do
      User.current = nil
      @request.session[:user_id] = 1 # permissions are hard
      user.update_attribute(:organization, organization)
      new_user.update_attribute(:organization, organization)
    end

    describe "PATCH /:id" do
      context "simple roles update" do

        it "updates a membership through an organization and adds a new entry in the project journal" do
          expect(project.users).to include user

          expect {
            patch :update, params: { id: organization.id, project_id: project.id, membership: { role_ids: [new_role.id], user_ids: [user.id] } }
          }.to change(project.journals, :count)

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to("/projects/ecookbook/settings/members")
          expect(project.journals).to_not be_nil
          if Redmine::Plugin.installed?(:redmine_limited_visibility)
            expect(project.journals.last.details.last).to have_attributes(
                                                            value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\",\"Developer\"],\"functions\":[]}",
                                                            old_value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\"],\"functions\":[]}"
                                                          )
          else
            expect(project.journals.last.details.last).to have_attributes(value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\",\"Developer\"]}",
                                                                          old_value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}")
          end
        end

        it "creates a membership through an organization and adds a new entry in the project journal" do
          expect(project.users).to include user
          expect(project.users).to_not include new_user

          expect {
            patch :update, params: { id: organization.id, project_id: project.id, membership: { role_ids: [role.id], user_ids: [user.id, new_user.id] } }
          }.to change(project.journals, :count).by(1)

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to("/projects/ecookbook/settings/members")
          expect(project.journals).to_not be_nil
          if Redmine::Plugin.installed?(:redmine_limited_visibility)
            expect(project.journals.last.details.last).to have_attributes(
                                                            value: "{\"name\":\"Robert Hill\",\"roles\":[\"Manager\"],\"functions\":[]}",
                                                            old_value: nil
                                                          )
          else
            expect(project.journals.last.details.last).to have_attributes(value: "{\"name\":\"Robert Hill\",\"roles\":[\"Manager\"]}",
                                                                          old_value: nil)
          end
        end

        it "deletes a membership through an organization and adds a new entry in the project journal" do
          expect(project.users).to include user
          member = Member.find_by(user: user, project: project)
          if Redmine::Plugin.installed?(:redmine_limited_visibility)
            member.functions = [function]
          end

          expect {
            patch :update, params: { id: organization.id, project_id: project.id, membership: { role_ids: [role.id], user_ids: [''] } }
          }.to change(project.journals, :count).by(1)

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to("/projects/ecookbook/settings/members")
          expect(project.journals).to_not be_nil
          if Redmine::Plugin.installed?(:redmine_limited_visibility)
            expect(project.journals.last.details.last).to have_attributes(
                                                            old_value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\"],\"functions\":[\"function3\"]}",
                                                            value: nil
                                                          )
          else
            expect(project.journals.last.details.last).to have_attributes(old_value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\"]}",
                                                                          value: nil)
          end
        end

      end

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        context "update roles and functions" do

          it "updates a membership through an organization and adds a new entry in the project journal" do
            expect {
              patch :update, params: { id: organization.id, project_id: project.id, membership: { role_ids: [new_role.id], user_ids: [user.id], function_ids: [function.id] } }
            }.to change(project.journals, :count)

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to("/projects/ecookbook/settings/members")
            expect(project.journals).to_not be_nil
            expect(project.journals.last.details.last).to have_attributes(value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\",\"Developer\"],\"functions\":[\"function3\"]}")
            expect(project.journals.last.details.last).to have_attributes(old_value: "{\"name\":\"John Smith\",\"roles\":[\"Manager\"],\"functions\":[]}")
          end
        end
      end
    end

    describe "non_members_roles (exception)" do

      before do
        OrganizationNonMemberRole.create(project_id: project.id, organization_id: organization.id, role_id: 1)
      end

      it "creates, adds a new entry in the project journal" do
        expect do
          post :create_non_members_roles, params: { project_id: project.id, membership: { organization_id: 2 } }
        end.to change { JournalDetail.count }.by(1)

        journal = JournalDetail.last
        expect(journal.property).to eq("members_exception")
        expect(journal.prop_key).to eq("members_exception_with_roles")
        expect(journal.value).to eq("{\"name\":\"Team A\",\"roles\":[\"Non member\"]}")
      end

      it "update roles, adds a new entry in the project journal" do
        expect do
          post :update_non_members_roles, params: { :id => organization.id, project_id: project.id, membership: { role_ids: ["2", "3"] } }
        end.to change { JournalDetail.count }.by(1)

        journal = JournalDetail.last

        expect(journal.property).to eq("members_exception")
        expect(journal.prop_key).to eq("members_exception_with_roles")
        expect(journal.old_value).to eq("{\"name\":\"Org A\",\"roles\":[\"Manager\"]}")
        expect(journal.value).to eq("{\"name\":\"Org A\",\"roles\":[\"Developer\",\"Reporter\"]}")
      end

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        it "update functions, adds a new entry in the project journal" do
          OrganizationNonMemberFunction.create(project_id: project.id, organization_id: organization.id, function_id: 1)

          expect do
            post :update_non_members_functions, params: { :id => organization.id, project_id: project.id, membership: { function_ids: ["2", "3"] } }
          end.to change { JournalDetail.count }.by(1)

          journal = JournalDetail.last
          expect(journal.property).to eq("members_exception")
          expect(journal.prop_key).to eq("members_exception_with_functions")
          expect(journal.old_value).to eq("{\"name\":\"Org A\",\"functions\":[\"function1\"]}")
          expect(journal.value).to eq("{\"name\":\"Org A\",\"functions\":[\"function2\",\"function3\"]}")
        end
      end

      it "adds a new entry in the project journal when deleting non-members roles" do
        expect do
          delete :destroy_non_members_roles, params: { :id => organization.id, project_id: project.id }
        end.to change { JournalDetail.count }.by(1)

        journal = JournalDetail.last

        expect(journal.property).to eq("members_exception")
        expect(journal.prop_key).to eq("members_exception_with_roles_functions")
        if Redmine::Plugin.installed?(:redmine_limited_visibility)
          expect(journal.old_value).to eq("{\"name\":\"Org A\",\"roles\":[\"Manager\"],\"functions\":[]}")
        else
          expect(journal.old_value).to eq("{\"name\":\"Org A\",\"roles\":[\"Manager\"]}")
        end
        expect(journal.value).to be_nil
      end

    end
  end
end
