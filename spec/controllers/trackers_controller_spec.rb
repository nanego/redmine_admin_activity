require 'spec_helper'

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
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:project) { projects(:projects_006) }
  let(:tracker) { project.trackers.find_by(name: "Bug") }

  describe "POST /" do
    before { post :create, params: { tracker: { name: "Tracker", default_status_id: 1, project_ids: [project.id] } } }

    it { expect(response).to redirect_to('/trackers') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "Tracker", :old_value => nil) }
  end

  describe "PATCH /:id" do
    let(:tracker) { trackers(:trackers_003) }
    before { patch :update, params: { id: tracker.id, tracker: { project_ids: [project.id] } } }

    it { expect(response).to redirect_to('/trackers') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => "Support request", :old_value => nil) }
  end

  describe "DELETE /:id" do
    let(:tracker) { Tracker.create(name: "To Be Removed Tracker", default_status_id: 1, projects: [project]) }

    before { delete :destroy, params: { id: tracker.id } }

    it { expect(response).to redirect_to('/trackers') }
    it { expect(project.journals).to_not be_nil }
    it { expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "To Be Removed Tracker") }
  end
end
