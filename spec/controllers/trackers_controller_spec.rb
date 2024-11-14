require 'rails_helper'

describe TrackersController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :members, :member_roles, :issues, :issue_statuses, :versions,
           :trackers, :projects_trackers, :issue_categories, :enabled_modules, :enumerations, :attachments,
           :workflows, :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details, :queries, :repositories, :changesets

  include Redmine::I18n

  before do
    @controller = TrackersController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session = ActionController::TestSession.new
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:project) { projects(:projects_006) }
  let(:tracker) { project.trackers.find_by(name: "Bug") }

  describe "POST /" do
    it "creates a new tracker and a new entry in the project journal" do
      post :create, params: { tracker: { name: "Tracker", default_status_id: 1, project_ids: [project.id] } }
      expect(response).to redirect_to('/trackers')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "Tracker", :old_value => nil)
    end
  end

  describe "PATCH /:id" do
    let(:tracker) { trackers(:trackers_003) }
    it "updates a tracker and adds a new entry in the project journal" do
      patch :update, params: { id: tracker.id, tracker: { project_ids: [project.id] } }
      expect(response).to redirect_to('/trackers')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "Support request", :old_value => nil)
    end
  end

  describe "DELETE /:id" do
    let(:tracker) { Tracker.create(name: "To Be Removed Tracker", default_status_id: 1, projects: [project]) }
    it "deletes a tracker and adds a new entry in the project journal" do
      delete :destroy, params: { id: tracker.id }
      expect(response).to redirect_to('/trackers')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "To Be Removed Tracker")
    end
  end
end
