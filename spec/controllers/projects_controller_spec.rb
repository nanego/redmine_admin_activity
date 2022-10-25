require 'spec_helper'

describe ProjectsController, type: :controller do

  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
            :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
            :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
            :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  fixtures :issue_template_projects, :issue_templates if Redmine::Plugin.installed?(:redmine_templates)
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
      patch :update, params: { id: 1, project: { enabled_module_names: ['issue_tracking', 'repository', 'documents'] } }

      project = Project.find(1)
      expect(response).to redirect_to('/projects/ecookbook/settings')
      expect(project.enabled_module_names.sort).to eq ['documents', 'issue_tracking', 'repository']
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:old_value => "issue_tracking,news", :value => "issue_tracking,repository,documents")
    end

    it "logs any disabled module" do
      Project.find(1).enabled_module_names = ['issue_tracking', 'news']
      patch :update, params: { id: 1, project: { :enabled_module_names => ['issue_tracking'] } }

      project = Project.find(1)
      expect(response).to redirect_to('/projects/ecookbook/settings')
      expect(project.enabled_module_names.sort).to eq ['issue_tracking']
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:old_value => "issue_tracking,news", :value => "issue_tracking")
    end
  end

  describe "POST /" do
    before do
      @request.session[:user_id] = 1
      post :copy, params: { id: 1, project: { name: "Test copy", identifier: "test-copy" } }
    end

    it "creates a new project duplicate from a source project and a new entry in the project journal" do
      project = Project.last
      expect(response).to redirect_to('/projects/test-copy/settings')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "eCookbook (id: 1)")
    end

    it "logs change on JournalSetting" do
      expect(JournalSetting.all).to be_present
      expect(JournalSetting.last.value_changes).to include({ "name" => [nil, "Test copy"] })
      expect(JournalSetting.last.value_changes).to include({ "source_project" => 1 })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Project")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "copy")
    end
  end

  describe "POST create" do
    it "logs change on JournalSetting" do
      post :create, :params => { :project => { "name" => "Test create", "identifier" => "test-create" } }

      expect(response).to redirect_to('/projects/test-create/settings')
      expect(JournalSetting.all).to be_present
      expect(JournalSetting.last.value_changes).to include({ "name" => ["", "Test create"] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Project")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "create")
    end
  end

  describe "DELETE destroy" do
    it "logs change on JournalSetting when we delete a parent project" do
      @request.session[:user_id] = 1

      # get project and descendants before destroying it
      projects = Project.find(1).self_and_descendants.to_a

      expect do
        delete :destroy, :params => { :id => "ecookbook", :confirm => 'ecookbook' }
      end.to change { JournalSetting.count }.by(5)

      expect(response).to redirect_to('/admin/projects')
      expect(JournalSetting.all).to be_present

      latest_journals = JournalSetting.last(5)
      5.times do |i|
        expect(latest_journals[i].value_changes).to include({ "name" => [projects[i].name, nil] })
        expect(latest_journals[i].value_changes).to include({ "parent_id" => [projects[i].parent_id, nil] })
        expect(latest_journals[i]).to have_attributes(:journalized_type => "Project")
        expect(latest_journals[i]).to have_attributes(:journalized_id => projects[i].id)
        expect(latest_journals[i]).to have_attributes(:journalized_entry_type => "destroy")
      end

    end
  end

  describe "POST archive" do
    it "add logs on JournalSetting and on the project journal for the project_root and its five children" do
      @request.session[:user_id] = 1
      post :archive, :params => { :id => "ecookbook" }

      expect(response).to redirect_to('/admin/projects')
      expect(JournalSetting.count).to eq(5)

      JournalSetting.last(5).each do |jorrnalsetting|
        expect(jorrnalsetting.value_changes).to include({ "status" => [Project::STATUS_ACTIVE, Project::STATUS_ARCHIVED] })
        expect(jorrnalsetting).to have_attributes(:journalized_type => "Project")
        expect(jorrnalsetting).to have_attributes(:journalized_entry_type => "archive")
      end

      Journal.last(5).each do |jorrnal|
        expect(jorrnal.details.last).to have_attributes(:old_value => "#{Project::STATUS_ACTIVE}", :value => "#{Project::STATUS_ARCHIVED}")
      end

    end
  end

  describe "POST unarchive" do
    before do
      @request.session[:user_id] = 1
    end

    it "add logs on JournalSetting and on the project journal only for the project_root but not for its children" do
      project = Project.find(1)
      project.status = Project::STATUS_ARCHIVED
      project.save
      post :unarchive, :params => { :id => "ecookbook" }

      expect(response).to redirect_to('/admin/projects')
      expect(JournalSetting.count).to eq(1)
      expect(JournalSetting.last.value_changes).to include({ "status" => [Project::STATUS_ARCHIVED, Project::STATUS_ACTIVE] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Project")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "active")
      expect(project.journals.last.details.last).to have_attributes(:old_value => "#{Project::STATUS_ARCHIVED}", :value => "#{Project::STATUS_ACTIVE}")
    end

    it "add logs on JournalSetting and on the project journal for the project_child and three ancestors" do
      Project.update_all :status => Project::STATUS_ARCHIVED
      post :unarchive, :params => { :id => "project6" }

      expect(response).to redirect_to('/admin/projects')
      expect(JournalSetting.count).to eq(3)

      JournalSetting.last(3).each do |journal|
        expect(journal.value_changes).to include({ "status" => [Project::STATUS_ARCHIVED, Project::STATUS_ACTIVE] })
        expect(journal).to have_attributes(:journalized_type => "Project")
        expect(journal).to have_attributes(:journalized_entry_type => "active")
      end

      Journal.last(3).each do |journal|
        expect(journal.details.last).to have_attributes(:old_value => "#{Project::STATUS_ARCHIVED}", :value => "#{Project::STATUS_ACTIVE}")
      end
    end

    it "add logs on JournalSetting and on the project journal only for the project_child when its ancestors are closed" do
      Project.update_all :status => Project::STATUS_CLOSED
      project = Project.find(6)
      project.update_attribute :status, Project::STATUS_ARCHIVED
      post :unarchive, :params => { :id => "project6" }

      expect(response).to redirect_to('/admin/projects')
      expect(JournalSetting.count).to eq(1)
      expect(JournalSetting.last.value_changes).to include({ "status" => [Project::STATUS_ARCHIVED, Project::STATUS_CLOSED] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "Project")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "close")
      expect(project.journals.last.details.last).to have_attributes(:old_value => "#{Project::STATUS_ARCHIVED}", :value => "#{Project::STATUS_CLOSED}")

    end
  end

  describe "POST close" do
    it "add logs on JournalSetting and on the project journal for the project_root and its five children" do
      @request.session[:user_id] = 1
      post :close, :params => { :id => "ecookbook" }

      expect(response).to redirect_to('/projects/ecookbook')
      expect(JournalSetting.count).to eq(5)

      JournalSetting.last(5).each do |journal|
        expect(journal.value_changes).to include({ "status" => [Project::STATUS_ACTIVE, Project::STATUS_CLOSED] })
        expect(journal).to have_attributes(:journalized_type => "Project")
        expect(journal).to have_attributes(:journalized_entry_type => "close")
      end

      Journal.last(5).each do |journal|
        expect(journal.details.last).to have_attributes(:old_value => "#{Project::STATUS_ACTIVE}", :value => "#{Project::STATUS_CLOSED}")
      end

    end
  end

  describe "POST reopen" do
    it "add logs on JournalSetting and on the project journal for the project_root and its five children" do
      @request.session[:user_id] = 1
      Project.update_all :status => Project::STATUS_CLOSED
      post :reopen, :params => { :id => "ecookbook" }

      expect(response).to redirect_to('/projects/ecookbook')
      expect(JournalSetting.count).to eq(5)

      JournalSetting.last(5).each do |journal|
        expect(journal.value_changes).to include({ "status" => [Project::STATUS_CLOSED, Project::STATUS_ACTIVE] })
        expect(journal).to have_attributes(:journalized_type => "Project")
        expect(journal).to have_attributes(:journalized_entry_type => "reopen")
      end

      Journal.last(5).each do |journal|
        expect(journal.details.last).to have_attributes(:old_value => "#{Project::STATUS_CLOSED}", :value => "#{Project::STATUS_ACTIVE}")
      end

    end
  end

  if Redmine::Plugin.installed?(:redmine_templates)
    describe "Trace template activation/deactivation in project history" do
      it "when activating a template on a project" do
        expect do
          patch :update, params: { id: 1, project: { issue_template_ids: ["1", "3"], tab: "issue_templates" } }
        end.to change { IssueTemplateProject.count }.by(2)
        .and change { JournalDetail.count }.by(2)
        expect(JournalDetail.last(2)[0].prop_key).to eq('enabled_template')
        expect(JournalDetail.last(2)[0].property).to eq('templates')
        expect(JournalDetail.last(2)[0].value).to eq(IssueTemplate.find(1).template_title)
        expect(JournalDetail.last(2)[1].value).to eq(IssueTemplate.find(3).template_title)
      end

      it "when deactivation a template on a project" do
        expect do
          patch :update, params: { id: 2, project: { issue_template_ids: ["1", "2", "3", "4", "5"], tab: "issue_templates" } }
        end.to change { IssueTemplateProject.count }.by(-1)
        .and change { JournalDetail.count }.by(1)
        expect(JournalDetail.last.prop_key).to eq('enabled_template')
        expect(JournalDetail.last.property).to eq('templates')
        expect(JournalDetail.last.old_value).to eq(IssueTemplate.find(6).template_title)
      end
    end
  end

  describe "Pagination of project history" do
    before do
      session[:per_page] = 3
    end

    it "check the number of elements by page" do
      # Generating 5 Journals Settings
      patch :update, :params => { :id => "ecookbook" , :project => { issue_template_ids: [], :name => 'Test changed name 1' }}
      patch :update, :params => { :id => "ecookbook" , :project => { issue_template_ids: [], :name => 'Test changed name 3' }}
      patch :update, :params => { :id => "ecookbook" , :project => { issue_template_ids: [], :name => 'Test changed name 2' }}
      patch :update, :params => { :id => "ecookbook" , :project => { issue_template_ids: [], :name => 'Test changed name 4' }}
      patch :update, :params => { :id => "ecookbook" , :project => { issue_template_ids: [], :name => 'Test changed name 5' }}

      # Get all journals of the first page
      get :settings, :params => { :id => Project.find(1).id, :tab => "admin_activity", page: 1}
      first_page = assigns(:journals)

      # Get all journals of the second page
      get :settings, :params => { :id => Project.find(1).id, :tab => "admin_activity", page: 2}
      second_page = assigns(:journals)

      # Tests
      expect(first_page.count).to eq(3)
      expect(second_page.count).to eq(2)
      expect(first_page.first.id).to be > second_page.first.id      
    end
  end
end
