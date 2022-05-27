require "spec_helper"

describe "JournalSettingsHelper" do
  include ApplicationHelper
  include PluginAdminActivity::JournalSettingsHelper
  include PluginAdminActivity::IssuesHelper

  fixtures :projects, :users

  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations
  end

  let!(:project_2) { Project.find(2) }

  before do
    set_language_if_valid('en')
    User.current = nil
  end

  describe "settings update" do
    it "should generate the right translated sentence for a Settings update" do
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "app_title" => ["Redmine test", "New redmine name"] })
      name = journal.value_changes.first[0]
      changes = journal.value_changes.first[1]
      expect(settings_update_text(name, changes)).to eq "Application title changed from <i>Redmine test</i> to <i>New redmine name</i>."
    end

    it "should generate the right translated sentence when ui theme is updated" do
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "ui_theme" => ["classic", "alternate"] })
      name = journal.value_changes.first[0]
      changes = journal.value_changes.first[1]
      expect(settings_update_text(name, changes)).to eq "Theme changed from <i>classic</i> to <i>alternate</i>."
    end
  end

  describe "Project creation" do
    it "should generate the right translated sentence for a project creation" do
      project = Project.new("name" => "Test create", "identifier" => "test-create")
      project.save
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => [nil, "Test create"] },
                                   :journalized => project,
                                   :journalized_entry_type => "create")
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/test-create\">Test create</a></i> has been created."
    end
  end

  describe "Project deletion" do
    it "should generate the right translated sentence for a project deletion" do
      project = projects(:projects_001)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => ["eCookbook", nil] },
                                   :journalized => project,
                                   :journalized_entry_type => "destroy")

      expect(project_update_text(journal)).to eq "Project <i>eCookbook</i> has been deleted."
    end

    it "should show logs of projects without link(html), when we delete it" do
      project = project_2
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_ACTIVE, Project::STATUS_ARCHIVED] },
                                   :journalized => project,
                                   :journalized_entry_type => "archive")
      journal.save
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_ARCHIVED, Project::STATUS_ACTIVE] },
                                   :journalized => project,
                                   :journalized_entry_type => "active")
      journal.save

      project.destroy
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => ["OnlineStore", nil] },
                                   :journalized => project,
                                   :journalized_entry_type => "destroy")
      journal.save
      expect(JournalSetting.count).to eq(3)
      expect(project_update_text(JournalSetting.first)).to eq "Project <i>OnlineStore</i> has been archived."
      expect(project_update_text(JournalSetting.second)).to eq "Project <i>OnlineStore</i> has been activated."
      expect(project_update_text(JournalSetting.last)).to eq "Project <i>OnlineStore</i> has been deleted."
    end
  end

  describe "Project duplication" do
    it "should generate the right translated sentence for a project duplication" do
      project = Project.new("name" => "Test create", "identifier" => "test-create")
      project.save
      source_project = Project.new("name" => "Source project", "identifier" => "source-project")
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => [nil, "Test create"],
                                                       "source_project" => 1000,
                                                       "source_project_name" => source_project.name },
                                   :journalized => project,
                                   :journalized_entry_type => "copy")

      source_project.save
      expect(project_update_text(journal)).to eq "Projet <i><a href=\"/projects/test-create\">Test create</a></i> has been copied from <i>Source project</i>."
    end
  end

  describe "Change the project status" do
    it "should generate the right translated sentence for a project reopening" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_CLOSED, Project::STATUS_ACTIVE] },
                                   :journalized => project,
                                   :journalized_entry_type => "reopen")

      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been reopened."
    end

    it "should generate the right translated sentence for a project closing" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_ACTIVE, Project::STATUS_CLOSED] },
                                   :journalized => project,
                                   :journalized_entry_type => "close")

      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been closed."
    end

    it "should generate the right translated sentence for a project changing from archiving to closing " do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_ARCHIVED, Project::STATUS_CLOSED] },
                                   :journalized => project,
                                   :journalized_entry_type => "close")

      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been changed from archived to Closed."
    end

    it "should generate the right translated sentence for a project archiving" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_ACTIVE, Project::STATUS_ARCHIVED] },
                                   :journalized => project,
                                   :journalized_entry_type => "archive")

      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been archived."
    end

    it "should generate the right translated sentence for a project activation" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Project::STATUS_ARCHIVED, Project::STATUS_ACTIVE] },
                                   :journalized => project,
                                   :journalized_entry_type => "active")

      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been activated."
    end

  end

  describe "User creation" do
    it "should generate the right translated sentence for a user creation" do
      user = User.new(:login => 'newuser',
                      :firstname => 'new',
                      :lastname => 'user',
                      :mail => 'newuser@example.net'
      )
      user.save
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "login" => ["", "newuser"], "firstname" => ["", "new"], "lastname" => ["", "user"] },
                                   :journalized => user,
                                   :journalized_entry_type => "create")
      expect(user_update_text(journal)).to eq "User <i><a href=\"/users/15\">new user</a></i> has been created."
    end
  end

  describe "Change the user status" do
    it "should generate the right translated sentence for a user activation" do
      user = User.find(7)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Principal::STATUS_REGISTERED, Principal::STATUS_ACTIVE] },
                                   :journalized => user,
                                   :journalized_entry_type => "active")
      expect(user_update_text(journal)).to eq "User <i><a href=\"/users/7\">Some One</a></i> has been activated."
    end

    it "should generate the right translated sentence for a user locking" do
      user = User.find(7)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Principal::STATUS_ACTIVE, Principal::STATUS_LOCKED] },
                                   :journalized => user,
                                   :journalized_entry_type => "lock")

      expect(user_update_text(journal)).to eq "User <i><a href=\"/users/7\">Some One</a></i> has been locked."
    end

    it "should generate the right translated sentence for a user unlocking" do
      user = User.find(7)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Principal::STATUS_LOCKED, Principal::STATUS_ACTIVE] },
                                   :journalized => user,
                                   :journalized_entry_type => "unlock")

      expect(user_update_text(journal)).to eq "User <i><a href=\"/users/7\">Some One</a></i> has been unlocked."
    end

  end

  describe "User deletion" do
    it "should generate the right translated sentence for a user deletion" do
      user = users(:users_007)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "login" => ["someone", nil], "firstname" => ["Some", nil], "lastname" => ["One", nil] },
                                   :journalized => user,
                                   :journalized_entry_type => "destroy")
      expect(user_update_text(journal)).to eq "User <i>Some One</i> has been deleted."
    end

    it "should show logs of users without link(html), when we delete it" do
      user = users(:users_007)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Principal::STATUS_ACTIVE, Principal::STATUS_LOCKED] },
                                   :journalized => user,
                                   :journalized_entry_type => "lock")
      journal.save
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "status" => [Principal::STATUS_LOCKED, Principal::STATUS_ACTIVE] },
                                   :journalized => user,
                                   :journalized_entry_type => "unlock")
      journal.save

      user.destroy
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "login" => ["someone", nil], "firstname" => ["Some", nil], "lastname" => ["One", nil] },
                                   :journalized => user,
                                   :journalized_entry_type => "destroy")
      journal.save
      expect(JournalSetting.count).to eq(3)
      expect(user_update_text(JournalSetting.first)).to eq "User <i>Some One</i> has been locked."
      expect(user_update_text(JournalSetting.second)).to eq "User <i>Some One</i> has been unlocked."
      expect(user_update_text(JournalSetting.last)).to eq "User <i>Some One</i> has been deleted."
    end

  end

  if Redmine::Plugin.installed?(:redmine_organizations)
    describe "organization creation / deletion" do
      it "should generate the right translated sentence for a organization creation (parent or child)" do
        # ex: Org A/Team B/Org child0/Org child1/Org child2
        3.times do |i|
          org = Organization.new(:name => "Org child#{i}", :parent_id => Organization.last.id)
          org.save

          journal = JournalSetting.new(:user_id => User.current.id,
                                       :value_changes => { "name" => [nil, org.name], "name_with_parents" => [nil, org.fullname] },
                                       :journalized => org,
                                       :journalized_entry_type => "create")

          expect(organization_update_text(journal)).to eq "Organization <i><a href=\"/organizations/#{org.id.to_s}\">#{org.fullname}</a></i> has been created."
        end
      end
    end

    it "should generate the right translated sentence for a organization deletion (parent or child)" do
      # ex: Org A/Team B/Org child0/Org child1/Org child2
      3.times do |i|
        org = Organization.new(:name => "Org child#{i}", :parent_id => Organization.last.id)
        org.save

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => { "name" => [org.name, nil], "name_with_parents" => [org.fullname, nil] },
                                     :journalized => org,
                                     :journalized_entry_type => "destroy")

        expect(organization_update_text(journal)).to eq "Organization <i>#{org.fullname}</i> has been deleted."
      end
    end

    describe "organization updating" do
      it "should generate the right translated sentence, when changing its parent" do
        org = Organization.last

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => {
                                       "name" => [org.name, "new_name"],
                                       "description" => [org.description, "new_des"],
                                       "parent_id" => [org.parent.id, 2],
                                       "direction" => [false, true],
                                       "mail" => [org.mail, "new_mail@test.com"],
                                     },
                                     :journalized => org,
                                     :journalized_entry_type => "update")

        expect(organization_update_text(journal)).to include(
                                                       "Organization <i><a href=\"/organizations/#{org.id}\">#{org.fullname}</a></i> has been updated.")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_name")} changed from #{org.name} to new_name")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_description")} changed from #{org.description} to new_des")

        expect(organization_update_text(journal)).to include(
                                                       l(:text_journal_belongs_to_changed, :class_name => "Organization",
                                                         :new => Organization.find(2).to_s,
                                                         :old => org.parent.to_s))

        # Here there is a boolean field, it will test both methods show_boolean_details and val_to_bool
        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_direction")} changed from #{l("label_0")} to #{l("label_1")}")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_mail")} changed from #{org.mail} to new_mail@test.com")
      end

      # test show_belongs_to_details When the absence of the new value
      it "should generate the right translated sentence, when removing its parent" do
        org = Organization.last

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => {
                                       "parent_id" => [org.parent.id, nil],
                                     },
                                     :journalized => org,
                                     :journalized_entry_type => "update")

        expect(organization_update_text(journal)).to include(
                                                       "Organization <i><a href=\"/organizations/#{org.id}\">#{org.fullname}</a></i> has been updated.")

        expect(organization_update_text(journal)).to include(
                                                       l(:text_journal_belongs_to_deleted, :class_name => "Organization",
                                                         :old => org.parent.to_s))
      end

      # test show_belongs_to_details When the absence of the old value
      it "should generate the right translated sentence, when adding the parent" do
        org = Organization.create(
          :name => 'org_name',
          :direction => true,
          :description => 'org_des',
          :name_with_parents => 'org_name',
          :parent_id => nil,)

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => {
                                       "parent_id" => [nil, Organization.first.id],
                                       "direction" => [true, false],
                                     },
                                     :journalized => org,
                                     :journalized_entry_type => "update")

        expect(organization_update_text(journal)).to include(
                                                       "Organization <i><a href=\"/organizations/#{org.id}\">#{org.fullname}</a></i> has been updated.")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_direction")} changed from #{l("label_1")} to #{l("label_0")}")

        expect(organization_update_text(journal)).to include(
                                                       l(:text_journal_belongs_to_added, :class_name => "Organization",
                                                         :new => Organization.first.to_s))
      end
    end

  end

  describe "custom field creation / deletion" do
    it "should generate the right translated sentence for a custom field creation, by using the function representative_link_path" do
      field = CustomField.new(:name => "test field",
                              :type => "IssueCustomField",
                              :field_format => "string")
      field.save

      journal = JournalSetting.new(:user_id => User.current.id,
                                    :value_changes => { "name" => ["", field.name], "field_format" => ["", "string"] },
                                    :journalized_id => field.id,
                                    :journalized_type => "IssueCustomField",
                                    :journalized_entry_type => "create")
      expect(custom_field_update_text(journal)).to eq "#{l(:label_custom_field)} <i><a href=\"#{CustomField.representative_link_path(field)}\">#{field.name}</a></i> has been created."
    end

    it "should generate the right translated sentence for a custom field deleting, by using the function representative_columns" do
      field = CustomField.new(:name => "test field",
                              :type => "IssueCustomField",
                              :field_format => "string")
      field.save

      journal = JournalSetting.new(:user_id => User.current.id,
                                    :value_changes => { "name" => [field.name, ""], "field_format" => ["string", ""] },
                                    :journalized_id => field.id,
                                    :journalized_type => "IssueCustomField",
                                    :journalized_entry_type => "destroy")

      expect(field.send CustomField.representative_columns[0]).to include(field.name)
      expect(custom_field_update_text(journal)).to eq "#{l(:label_custom_field)} <i>#{field.name}</i> has been deleted."
    end
  end

  describe "custom filed updating" do
    it "should generate the right translated sentence, when changing its attributes and its has_and_belongs_to_many association" do
      field = IssueCustomField.last

      journal = JournalSetting.new(:user_id => User.current.id,
                                    :value_changes => {
                                      "name" => [field.name, "new_name"],
                                      "description" => [field.description, "new_des"],
                                      "is_required" => [false, true],
                                      "roles" => [[], [1]],
                                      "projects" => [[1], [1, 2]],
                                    },
                                    :journalized_id => field.id,
                                    :journalized_type => "IssueCustomField",
                                    :journalized_entry_type => "update")


      expect(custom_field_update_text(journal)).to include(
        "#{l(:label_custom_field)} <i><a href=\"#{CustomField.representative_link_path(field)}\">#{field.name}</a></i> has been updated.")

      expect(custom_field_update_text(journal)).to include(
        "#{l("field_name")} changed from #{field.name} to new_name")

      expect(custom_field_update_text(journal)).to include(
        "#{l(:label_project_plural)} have been changed from [#{Project.find(1).name}] to [#{Project.find(1).name}, #{Project.find(2).name}]")
      expect(custom_field_update_text(journal)).to include(
        "#{l(:label_role_plural)} have been changed from [] to [#{Role.find(1).name}]")
    end

    it "should generate the right translated sentence, when changing has_and_belongs_to_many association (case of association deleting show(#id))" do
      field = IssueCustomField.last
      pro = Project.create(name: 'test', identifier: 'test')
      journal = JournalSetting.new(:user_id => User.current.id,
                                    :value_changes => {
                                      "name" => [field.name, "new_name"],
                                      "description" => [field.description, "new_des"],
                                      "projects" => [[1], [1, pro.id]],
                                    },
                                    :journalized_id => field.id,
                                    :journalized_type => "IssueCustomField",
                                    :journalized_entry_type => "update")
      pro.delete
      expect(custom_field_update_text(journal)).to include(
        "#{l(:label_project_plural)} have been changed from [#{Project.find(1).name}] to [#{Project.find(1).name}, ##{pro.id}]")
    end

    it "should generate the right translated sentence, when changing the enumerations(test the function show_has_many_details)" do
      field = CustomField.new(:name => "test field",
        :type => "IssueCustomField",
        :field_format => "enumeration")
      field.save

      c_f_e1 = CustomFieldEnumeration.create(name: 'val1', position: 1, active: true, custom_field_id: field.id)
      c_f_e2 = CustomFieldEnumeration.create(name: 'val2', position: 1, active: true, custom_field_id: field.id)

      journal = JournalSetting.new(:user_id => User.current.id,
                                    :value_changes => {
                                      "enumerations" => [[c_f_e1.id], [c_f_e1.id, c_f_e2.id]],
                                    },
                                    :journalized_id => field.id,
                                    :journalized_type => "IssueCustomField",
                                    :journalized_entry_type => "update")
      c_f_e2.delete

      expect(custom_field_update_text(journal)).to include(
        "#{l(:label_customfieldenumeration)} has been changed from [#{c_f_e1.name}] to [#{c_f_e1.name}, ##{c_f_e2.id}]")
    end

    describe "organization updating" do
      it "should generate the right translated sentence, when changing its parent" do
        org = Organization.last

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => {
                                       "name" => [org.name, "new_name"],
                                       "description" => [org.description, "new_des"],
                                       "parent_id" => [org.parent.id, 2],
                                       "direction" => [false, true],
                                       "mail" => [org.mail, "new_mail@test.com"],
                                     },
                                     :journalized => org,
                                     :journalized_entry_type => "update")

        expect(organization_update_text(journal)).to include(
                                                       "Organization <i><a href=\"/organizations/#{org.id}\">#{org.fullname}</a></i> has been updated.")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_name")} changed from #{org.name} to new_name")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_description")} changed from #{org.description} to new_des")

        expect(organization_update_text(journal)).to include(
                                                       l(:text_journal_belongs_to_changed, :class_name => "Organization",
                                                         :new => Organization.find(2).to_s,
                                                         :old => org.parent.to_s))

        # Here there is a boolean field, it will test both methods show_boolean_details and val_to_bool
        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_direction")} changed from #{l("label_0")} to #{l("label_1")}")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_mail")} changed from #{org.mail} to new_mail@test.com")
      end

      # test show_belongs_to_details When the absence of the new value
      it "should generate the right translated sentence, when removing its parent" do
        org = Organization.last

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => {
                                       "parent_id" => [org.parent.id, nil],
                                     },
                                     :journalized => org,
                                     :journalized_entry_type => "update")

        expect(organization_update_text(journal)).to include(
                                                       "Organization <i><a href=\"/organizations/#{org.id}\">#{org.fullname}</a></i> has been updated.")

        expect(organization_update_text(journal)).to include(
                                                       l(:text_journal_belongs_to_deleted, :class_name => "Organization",
                                                         :old => org.parent.to_s))
      end

      # test show_belongs_to_details When the absence of the old value
      it "should generate the right translated sentence, when adding the parent" do
        org = Organization.create(
          :name => 'org_name',
          :direction => true,
          :description => 'org_des',
          :name_with_parents => 'org_name',
          :parent_id => nil,)

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => {
                                       "parent_id" => [nil, Organization.first.id],
                                       "direction" => [true, false],
                                     },
                                     :journalized => org,
                                     :journalized_entry_type => "update")

        expect(organization_update_text(journal)).to include(
                                                       "Organization <i><a href=\"/organizations/#{org.id}\">#{org.fullname}</a></i> has been updated.")

        expect(organization_update_text(journal)).to include(
                                                       "#{l("field_direction")} changed from #{l("label_1")} to #{l("label_0")}")

        expect(organization_update_text(journal)).to include(
                                                       l(:text_journal_belongs_to_added, :class_name => "Organization",
                                                         :new => Organization.first.to_s))
      end
    end

  end
end
