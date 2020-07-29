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
    end

    before do
      @controller = described_class.new
      @request = ActionDispatch::TestRequest.create
      @response = ActionDispatch::TestResponse.new
      User.current = nil
      @request.session[:user_id] = 1 #permissions are hard
    end

    describe "PATCH /:id" do
      context "simple roles update" do
        let(:organization) { organizations(:organization_001) }
        let(:project)      { projects(:projects_001) }
        let(:role)         { roles(:roles_002) }
        let(:user)         { users(:users_002) }

        it "updates a custom_field and adds a new entry in the project journal" do
          patch :update, params: { id: organization.id, project_id: project.id, membership: { role_ids: [role.id], user_ids: [user.id] } }

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to("/projects/ecookbook/settings/members")
          expect(project.journals).to_not be_nil
          if Redmine::Plugin.installed?(:redmine_limited_visibility)
            expect(project.journals.last.details.last).to have_attributes(value: "{\"name\":\"John Smith\",\"roles\":[\"Developer\"],\"functions\":[]}")
          else
            expect(project.journals.last.details.last).to have_attributes(value: "{\"name\":\"John Smith\",\"roles\":[\"Developer\"]}")
          end
          expect(project.journals.last.details.last).to have_attributes(old_value: nil)
        end
      end

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        context "update roles and functions" do
          let(:organization) { organizations(:organization_001) }
          let(:project)      { projects(:projects_001) }
          let(:role)         { roles(:roles_002) }
          let(:function)     { functions(:functions_003) }
          let(:user)         { users(:users_002) }

          it "updates a custom_field and adds a new entry in the project journal" do
            patch :update, params: { id: organization.id, project_id: project.id, membership: { role_ids: [role.id], user_ids: [user.id], function_ids: [function.id] } }

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to("/projects/ecookbook/settings/members")
            expect(project.journals).to_not be_nil
            expect(project.journals.last.details.last).to have_attributes(value: "{\"name\":\"John Smith\",\"roles\":[\"Developer\"],\"functions\":[\"function3\"]}")
            expect(project.journals.last.details.last).to have_attributes(old_value: nil)
          end
        end
      end
    end
  end
end
