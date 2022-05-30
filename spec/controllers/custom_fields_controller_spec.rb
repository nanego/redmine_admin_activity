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

  let!(:project) { projects(:projects_001) }

  describe "POST /creates" do
    it "creates a new custom_field and a new entry in the project journal" do
      post :create, params: { type: "IssueCustomField", custom_field: { name: "CustomField",
                                                                        project_ids: [project.id],
                                                                        field_format: "string" } }
      expect(response).to redirect_to(custom_fields_path({ :tab => "IssueCustomField" }))
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "CustomField", :old_value => nil)
    end

    it "logs change on JournalSetting" do
      post :create, params: { type: "IssueCustomField",
                              custom_field: {
                                field_format: "string",
                                name: "test",
                                description: "des test",
                                role_ids: ["1", "2"],
                                tracker_ids: ["3"],
                                project_ids: ["1", "2"] }
                              }

      expect(JournalSetting).to_not be_nil

      expect(JournalSetting.last.value_changes).to include({ "name" => ["", "test"] })
      expect(JournalSetting.last.value_changes).to include({ "description" => [nil, "des test"] })
      expect(JournalSetting.last.value_changes).to include({ "roles" => [nil, [1, 2]] })
      expect(JournalSetting.last.value_changes).to include({ "projects" => [nil, [1, 2]] })
      expect(JournalSetting.last.value_changes).to include({ "trackers" => [nil, [3]] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "IssueCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "create")
      expect(JournalSetting.last).to have_attributes(:journalized_id => CustomField.last.id)
    end

  end

  describe "PATCH /:id" do
    let!(:custom_field) { custom_fields(:custom_fields_002) }
    it "updates a custom_field and adds a new entry in the project journal" do
      patch :update, params: { id: custom_field.id, custom_field: { project_ids: [project.id] } }
      expect(response).to redirect_to('/custom_fields/2/edit')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => "Searchable field", :old_value => nil)
    end

    it "logs change on JournalSetting when we update a ProjectCustomField" do
      field = ProjectCustomField.first
      expect do
        patch :update, :params => {
          :id => field.id,
          :custom_field => {
            :name => "new_name",
            :description => "new_des",
            :is_required => true,
          }
        }
      end.to change { JournalSetting.count }.by(1)

      expect(JournalSetting.last.value_changes).to include({ "name" => [field.name, "new_name"] })
      expect(JournalSetting.last.value_changes).to include({ "description" => [field.description, "new_des"] })
      expect(JournalSetting.last.value_changes).to include({ "is_required" => [false, true] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "ProjectCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_id => field.id)
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "update")
    end
  end

  describe "DELETE /:id" do
    let(:custom_field) { CustomField.create(name: "To Be Removed CustomField", field_format: "string", visible: "1", type: "IssueCustomField", projects: [project]) }
    it "deletes a custom_field and adds a new entry in the project journal" do
      delete :destroy, params: { id: custom_field.id }
      expect(response).to redirect_to('/custom_fields?tab=IssueCustomField')
      expect(project.journals).to_not be_nil
      expect(project.journals.last.details.last).to have_attributes(:value => nil, :old_value => "To Be Removed CustomField")
    end

    it "logs change on JournalSetting" do
      field = IssueCustomField.create(:name => 'field test', field_format: "string")
      id = IssueCustomField.last.id
      delete :destroy, :params => { :id => id, :confirm => true }

      expect(JournalSetting).to_not be_nil
      expect(JournalSetting.last.value_changes).to include({ "name" => [field.name, nil] })
      expect(JournalSetting.last.value_changes).to include({ "field_format" => [field.field_format, nil] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "IssueCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_id => id)
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "destroy")
    end
  end
end
