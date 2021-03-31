require 'spec_helper'

describe IssueCategoriesController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    User.current = nil
    @request.session[:user_id] = 2 #permissions are hard
  end

  let(:project) { Project.find(1) }
  let(:issue_category) { project.issue_categories.find_by(name: "Printing") }

  describe "POST /" do
    it "creates a new category and a new entry in the project journal" do
      post :create, params: { project_id: project.id, issue_category: { name: "Issue Category" } }
      expect(response).to redirect_to('/projects/ecookbook/settings/categories')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "Issue Category", :old_value => nil)
    end

    it "sanitizes category name in project journal to prevent cross-site scripting" do
      post :create, params: { project_id: project.id, issue_category: { name: "<script>alert('xss')</script>" } }
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "alert('xss')")
    end
  end

  describe "PATCH /:id" do
    it "updates a category and adds a new entry in the project journal" do
      patch :update, params: { project_id: project.id, id: issue_category.id, issue_category: { name: "New name" } }
      expect(response).to redirect_to('/projects/ecookbook/settings/categories')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "New name", :old_value => "Printing")
    end

    it "sanitizes category name in project journal to prevent cross-site scripting" do
      issue_category.update!(name: "<script>alert('old_xss')</script>")
      patch :update, params: { project_id: project.id, id: issue_category.id, issue_category: { name: "<script>alert('xss')</script>" } }

      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "alert('xss')", :old_value => "alert('old_xss')")
    end
  end

  describe "DELETE /:id" do
    let(:issue_category) { IssueCategory.create(project: project, name: "To Be Removed Issue Category") }
    it "deletes a category and adds a new entry in the project journal" do
      delete :destroy, params: { id: issue_category.id }
      expect(response).to redirect_to('/projects/ecookbook/settings/categories')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "To Be Removed Issue Category")
    end

    it "sanitizes category name in project journal to prevent cross-site scripting" do
      issue_category.update!(name: "<script>alert('old_value')</script>")
      delete :destroy, params: { id: issue_category.id }
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "alert('old_value')")
    end
  end
end
