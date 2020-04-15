require "spec_helper"

describe "JournalSettingsHelper" do
  include ApplicationHelper
  include PluginAdminActivity::JournalSettingsHelper

  fixtures :projects

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
    it "should generate the right translated sentence for a project creation (project still exists)" do
      project = projects(:projects_001)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => project.previous_changes,
                                   :journalized => project,
                                   :journalized_entry_type => "create")
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been created."
    end

    it "should generate the right translated sentence for a project creation (project doesn't exist anymore)" do
      project = Project.new("name" => "Test create", "identifier" => "test-create")
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => [nil, "eCookbook"] },
                                   :journalized => project,
                                   :journalized_entry_type => "create")

      expect(project_update_text(journal)).to eq "Project <i>eCookbook</i> has been created."
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
  end

  describe "Project duplication" do
    it "should generate the right translated sentence for a project duplication (projects still exist)" do
      project = projects(:projects_001)
      source_project = projects(:projects_002)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "source_project" => source_project.id,
                                                       "source_project_name" => source_project.name },
                                   :journalized => project,
                                   :journalized_entry_type => "copy")

      expect(project_update_text(journal)).to eq "Projet <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been copied from <i><a href=\"/projects/onlinestore\">OnlineStore</a></i>."
    end

    it "should generate the right translated sentence for a project duplication (projects don't exist anymore)" do
      project = Project.new("name" => "Test create", "identifier" => "test-create")
      source_project = Project.new("name" => "Source project", "identifier" => "source-project")
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => [nil, "eCookbook"],
                                                       "source_project" => 1000,
                                                       "source_project_name" => source_project.name },
                                   :journalized => project,
                                   :journalized_entry_type => "copy")

      expect(project_update_text(journal)).to eq "Projet <i>eCookbook</i> has been copied from <i>Source project</i>."
    end
  end
end
