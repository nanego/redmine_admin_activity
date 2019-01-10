require 'spec_helper'

describe ProjectsController, type: :controller do

  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    @controller = ProjectsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 2 #permissions are hard
  end

  describe "POST modules" do

    it "logs any enabled module" do
      Project.find(1).enabled_module_names = ['issue_tracking', 'news']
      patch :update, params: {id: 1, project: {enabled_module_names: ['issue_tracking', 'repository', 'documents']}}

      project = Project.find(1)
      expect(response).to redirect_to('/projects/ecookbook/settings')
      expect(project.enabled_module_names.sort).to eq ['documents', 'issue_tracking', 'repository']
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:old_value => "issue_tracking,news", :value => "issue_tracking,repository,documents")
    end

    it "logs any disabled module" do
      Project.find(1).enabled_module_names = ['issue_tracking', 'news']
      patch :update, params: {id: 1, project: {:enabled_module_names => ['issue_tracking']}}

      project = Project.find(1)
      expect(response).to redirect_to('/projects/ecookbook/settings')
      expect(project.enabled_module_names.sort).to eq ['issue_tracking']
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:old_value => "issue_tracking,news", :value => "issue_tracking")
    end

  end

end
