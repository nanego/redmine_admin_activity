require 'spec_helper'

describe CustomFieldsController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    @controller = CustomFieldsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:custom_fields_project) { custom_fields_projects(:custom_fields_projects_001) }
  let(:project) { custom_fields_project.project }
  let(:custom_field) { custom_fields_project.custom_field }

  describe "POST /" do
    before { post :create, params: { custom_field: { name: "CustomField", type: "IssueCustomField", project_ids: [project.id] } } }

    it { expect(response).to redirect_to('/custom_fields') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "CustomField", :old_value => nil) }
  end

  describe "PATCH /:id" do
    let(:custom_field) { custom_fields(:custom_fields_003) }
    before { patch :update, params: { id: custom_field.id, custom_field: { project_ids: [project.id] } } }

    it { expect(response).to redirect_to('/custom_fields') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "Support request", :old_value => nil) }
  end

  describe "DELETE /:id" do
    let(:custom_field) { CustomField.create(name: "To Be Removed CustomField", type: "IssueCustomField", projects: [project]) }

    before { delete :destroy, params: { id: custom_field.id } }

    it { expect(response).to redirect_to('/custom_fields') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "To Be Removed CustomField") }
  end
end
