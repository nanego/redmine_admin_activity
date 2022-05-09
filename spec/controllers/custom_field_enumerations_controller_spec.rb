require 'spec_helper'

describe CustomFieldEnumerationsController, type: :controller do
  render_views

  fixtures :projects, :users, :roles, :enumerations,
            :custom_fields, :custom_values, :custom_fields_projects

  include Redmine::I18n

  before do
    @controller = CustomFieldEnumerationsController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions are hard
    ProjectCustomField.create(:name => 'field test', field_format: "enumeration")
  end
  let!(:id) { ProjectCustomField.last.id }

  describe "POST /creates" do
    it "logs change on JournalSetting" do
      expect do
        post :create,
              params: { custom_field_enumeration: { name: "test enumeration" }, custom_field_id: id }
      end.to change { JournalSetting.count }.by(1)
      .and change{ CustomFieldEnumeration.count }.by(1)

      expect(JournalSetting.last.value_changes).to include({ "enumerations" => [[], [CustomFieldEnumeration.last.id]] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "ProjectCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "update")
      expect(JournalSetting.last).to have_attributes(:journalized_id => id)
    end
  end

  describe "PUT" do
    it "logs change on JournalSetting when deactivate a customField enumeration" do
      c_f_e1_id =  CustomFieldEnumeration.create(name: 'val1', position: 1, active: true, custom_field_id: id).id
      c_f_e2_id = CustomFieldEnumeration.create(name: 'val2', position: 2, active: true, custom_field_id: id).id
      put :update_each,
          :params => {
          :custom_field_id => id,
          :custom_field_enumerations => {
            c_f_e1_id => {
              :position => "1",
              :name => "val1",
              :active => "1"
            },
            c_f_e2_id => {
              :position => "2",
              :name => "val2",
              :active => "0"
            }
          }
        }
      expect(JournalSetting.last.value_changes).to include({ "enumerations" => [[c_f_e1_id, c_f_e2_id], [c_f_e1_id]] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "ProjectCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "update")
      expect(JournalSetting.last).to have_attributes(:journalized_id => id)
    end

    it "logs change on JournalSetting when activate a customField enumeration" do
      c_f_e1_id =  CustomFieldEnumeration.create(name: 'val1', position: 1, active: true, custom_field_id: id).id
      c_f_e2_id = CustomFieldEnumeration.create(name: 'val2', position: 2, active: false, custom_field_id: id).id
      put :update_each,
          :params => {
          :custom_field_id => id,
          :custom_field_enumerations => {
            c_f_e1_id => {
              :position => "1",
              :name => "val1",
              :active => "1"
            },
            c_f_e2_id => {
              :position => "2",
              :name => "val2",
              :active => "1"
            }
          }
        }
      expect(JournalSetting.last.value_changes).to include({ "enumerations" => [[c_f_e1_id], [c_f_e1_id, c_f_e2_id]] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "ProjectCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "update")
      expect(JournalSetting.last).to have_attributes(:journalized_id => id)
    end
  end

  describe "DELETE /:id" do
    it "logs change on JournalSetting" do
      c_f_e1_id =  CustomFieldEnumeration.create(name: 'val1', position: 1, active: true, custom_field_id: id).id
      c_f_e2_id = CustomFieldEnumeration.create(name: 'val2', position: 2, active: true, custom_field_id: id).id

      expect do
        delete :destroy, :params => { :id => c_f_e2_id, custom_field_id: id , :confirm => true }
      end.to change { JournalSetting.count }.by(1)
      .and change{ CustomFieldEnumeration.count }.by(-1)

      expect(JournalSetting.last.value_changes).to include({ "enumerations" => [[c_f_e1_id, c_f_e2_id], [c_f_e1_id]] })
      expect(JournalSetting.last).to have_attributes(:journalized_type => "ProjectCustomField")
      expect(JournalSetting.last).to have_attributes(:journalized_entry_type => "update")
      expect(JournalSetting.last).to have_attributes(:journalized_id => id)
    end
  end
end
