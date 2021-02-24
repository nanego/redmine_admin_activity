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
    it "should generate the right translated sentence for a project creation" do
      project = Project.new("name" => "Test create", "identifier" => "test-create")
      project.save
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => [nil, "eCookbook"] },
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
  end

  describe "Project duplication" do
    it "should generate the right translated sentence for a project duplication" do
      project = Project.new("name" => "Test create", "identifier" => "test-create")
      project.save
      source_project = Project.new("name" => "Source project", "identifier" => "source-project")
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => [nil, "eCookbook"],
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
                                  :value_changes => { "status" => [5,1] },
                                  :journalized => project,
                                  :journalized_entry_type => "reopen")
      
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been reopened."
    end

    it "should generate the right translated sentence for a project closing" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                  :value_changes => { "status" => [1,5] },
                                  :journalized => project,
                                  :journalized_entry_type => "close")
      
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been closed."
    end

    it "should generate the right translated sentence for a project changing from archiving to closing " do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                  :value_changes => { "status" => [9,5] },
                                  :journalized => project,
                                  :journalized_entry_type => "close")
      
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been changed from archived to Closed."
    end

    it "should generate the right translated sentence for a project archiving" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                  :value_changes => { "status" => [1,9] },
                                  :journalized => project,
                                  :journalized_entry_type => "archive")
      
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been archived."
    end

    it "should generate the right translated sentence for a project activation" do
      project = Project.find(1)
      journal = JournalSetting.new(:user_id => User.current.id,
                                  :value_changes => { "status" => [9,1] },
                                  :journalized => project,
                                  :journalized_entry_type => "active")
      
      expect(project_update_text(journal)).to eq "Project <i><a href=\"/projects/ecookbook\">eCookbook</a></i> has been activated."
    end

  end
end
