require 'spec_helper'

describe IssueCategoriesController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    @controller = IssueCategoriesController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 2 #permissions are hard
  end

  let(:project) { Project.find(1) }

  describe "POST /" do
    before { post :create, params: { project_id: project.id, issue_category: { name: "Issue Category" } } }

    it { expect(response).to redirect_to('/projects/ecookbook/settings/categories') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "Issue Category", :old_value => nil) }
  end

  describe "DELETE /:id" do
    let(:issue_category) { IssueCategory.create(project: project, name: "To Be Removed Issue Category") }

    before { delete :destroy, params: { id: issue_category.id } }

    it { expect(response).to redirect_to('/projects/ecookbook/settings/categories') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "To Be Removed Issue Category") }
  end
end
