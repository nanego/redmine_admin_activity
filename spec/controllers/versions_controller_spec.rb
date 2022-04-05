require 'spec_helper'

describe VersionsController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    @controller = VersionsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:project) { projects(:projects_001) }
  let(:version) { project.versions.find_by(name: "2.0") }

  describe "POST /" do
    it "creates a new version and a new entry in the project journal" do
      post :create, params: { project_id: project.id, version: { name: "1.0.0" } }
      expect(response).to redirect_to('/projects/ecookbook/settings/versions')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "1.0.0", :old_value => nil)
    end
  end

  describe "PATCH /:id" do
    it "updates a version and adds a new entry in the project journal" do
      patch :update, params: { id: version.id, version: { name: "2.1" } }
      expect(response).to redirect_to('/projects/ecookbook/settings/versions')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "2.1", :old_value => "2.0")
    end
  end

  describe "DELETE /:id" do
    it "deletes a version and adds a new entry in the project journal" do
      delete :destroy, params: { id: version.id }
      expect(response).to redirect_to('/projects/ecookbook/settings/versions')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "2.0")
    end
  end
end
