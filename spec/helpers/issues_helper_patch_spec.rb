require "spec_helper"

describe "IssuesHelperPatch" do
  include ApplicationHelper
  include IssuesHelper
  include CustomFieldsHelper
  include ERB::Util
  include ActionView::Helpers::TagHelper

  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :projects_trackers,
           :roles,
           :member_roles,
           :members,
           :enabled_modules,
           :custom_fields,
           :attachments,
           :versions

  before do
    set_language_if_valid('en')
    User.current = nil
  end

  describe "modules property" do
    it "should IssuesHelper#show_detail with no_html should show a changing enabled modules" do
      detail = JournalDetail.new(:property => 'modules', :old_value => ['module1'], :value => ['module1', 'module2'], :prop_key => 'modules')
      expect(show_detail(detail, true)).to eq "Enabled modules changed: removed [[\"module1\"]] and added [[\"module1\",  \"module2\"]]"
    end

    it "should IssuesHelper#show_detail with no_html should show a deleted enabled modules" do
      detail = JournalDetail.new(:property => 'modules', :old_value => ['module1'], :value => nil, :prop_key => 'modules')
      expect(show_detail(detail, true)).to eq "Enabled modules changed: removed [[\"module1\"]]  "
    end

    it "should IssuesHelper#show_detail with html should show a new enabled module with HTML highlights" do
      detail = JournalDetail.new(:property => 'modules', :old_value => nil, :value => ['module1'], :prop_key => 'modules')
      detail.id = 1
      result = show_detail(detail, false)
      expect(result).to include("Enabled modules changed:  added [[\"module1\"]]")
    end

    it "should IssuesHelper#show_detail with html should show a deleted enabled modules with HTML highlights" do
      detail = JournalDetail.new(:property => 'modules', :old_value => ['module1'], :value => nil, :prop_key => 'modules')
      html = show_detail(detail, false)
      expect(html).to include("Enabled modules changed: removed [[\"module1\"]]")
    end

    it "should IssuesHelper#show_detail with html should show all new enabled modules with HTML highlights" do
      detail = JournalDetail.new(:property => 'modules', :old_value => nil, :value => ['module1', 'module2'], :prop_key => 'modules')
      detail.id = 1
      result = show_detail(detail, false)
      html = "Enabled modules changed:  added [[\"module1\",  \"module2\"]]"
      expect(result).to include(html)
    end

    it "should IssuesHelper#show_detail with html should show all deleted enabled modules with HTML highlights" do
      detail = JournalDetail.new(:property => 'modules', :old_value => ['module1', 'module2'], :value => nil, :prop_key => 'modules')
      result = show_detail(detail, false)
      html = "Enabled modules changed: removed [[\"module1\",  \"module2\"]]"
      expect(result).to include(html)
    end
  end

  describe "functions property" do
    it "shows a new enabled function with HTML highlights" do
      detail = JournalDetail.new(:property => 'functions', :old_value => 'function_1', :value => 'function_1,function_2', :prop_key => 'functions')
      expect(show_detail(detail, false)).to eq "Enabled functions changed: added [function_2]"
    end
  end

  describe "templates property" do
    it "shows a new enabled template with HTML highlights" do
      detail = JournalDetail.new(:property => 'templates', :old_value => nil, :value => 'template-name', :prop_key => 'enabled_template')
      expect(show_detail(detail, false)).to eq 'New template enabled: ["template-name"]'
    end
  end

  describe "members property" do
    describe "members property with legacy Array format" do
      it "should IssuesHelper#show_detail with no_html should show a changing enabled members" do
        detail = JournalDetail.new(:property => 'members', :old_value => ['user1'], :value => ['user1', 'user2'], :prop_key => 'members')
        expect(show_detail(detail, true)).to eq "Members changed: removed [[\"user1\"]] and added [[\"user1\",  \"user2\"]]"
      end

      it "should IssuesHelper#show_detail with no_html should show a deleted members" do
        detail = JournalDetail.new(:property => 'members', :old_value => ['user1'], :value => nil, :prop_key => 'members')
        expect(show_detail(detail, true)).to eq "Members changed: removed [[\"user1\"]]  "
      end

      it "should IssuesHelper#show_detail with html should show a new member with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => nil, :value => ['user1'], :prop_key => 'members')
        detail.id = 1
        result = show_detail(detail, false)
        expect(result).to include("Members changed:  added [[\"user1\"]]")
      end

      it "should IssuesHelper#show_detail with html should show a deleted members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => ['user1'], :value => nil, :prop_key => 'members')
        html = show_detail(detail, false)
        expect(html).to include("Members changed: removed [[\"user1\"]]")
      end

      it "should IssuesHelper#show_detail with html should show all new members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => nil, :value => ['user1', 'user2'], :prop_key => 'members')
        detail.id = 1
        result = show_detail(detail, false)
        html = "Members changed:  added [[\"user1\",  \"user2\"]]"
        expect(result).to include(html)
      end

      it "should IssuesHelper#show_detail with html should show all deleted members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => ['user1', 'user2'], :value => nil, :prop_key => 'members')
        result = show_detail(detail, false)
        html = "Members changed: removed [[\"user1\",  \"user2\"]]"
        expect(result).to include(html)
      end
    end

    describe "members property with new JSON format" do
      it "should IssuesHelper#show_detail with no_html should show a changing enabled members" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"]}', :value => '{"name":"user1","roles":["Developer", "Manager"]}', :prop_key => 'member_with_roles')
        expect(show_detail(detail, true)).to eq "Roles of member user1 have been changed from [Developer] to [Developer, Manager]"
      end

      it "should IssuesHelper#show_detail with no_html should show a deleted members" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"]}', :value => nil, :prop_key => 'member_with_roles')
        expect(show_detail(detail, true)).to eq "Member user1, with roles [Developer], has been removed"
      end

      it "should IssuesHelper#show_detail with html should show a new member with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => nil, :value => '{"name":"user1","roles":["Developer"]}', :prop_key => 'member_with_roles')
        detail.id = 1
        result = show_detail(detail, false)
        expect(result).to include("Member user1 has been added with roles [Developer]")
      end

      it "should IssuesHelper#show_detail with html should show a deleted members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"]}', :value => nil, :prop_key => 'member_with_roles')
        html = show_detail(detail, false)
        expect(html).to include("Member user1, with roles [Developer], has been removed")
      end

      it "should IssuesHelper#show_detail with html should show all new members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => nil, :value =>  '{"name":"user1","roles":["Developer", "Manager"]}', :prop_key => 'member_with_roles')
        detail.id = 1
        result = show_detail(detail, false)
        html = "Member user1 has been added with roles [Developer, Manager]"
        expect(result).to include(html)
      end

      it "should IssuesHelper#show_detail with html should show all deleted members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value =>  '{"name":"user1","roles":["Developer", "Manager"]}', :value => nil, :prop_key => 'member_with_roles')
        result = show_detail(detail, false)
        html = "Member user1, with roles [Developer, Manager], has been removed"
        expect(result).to include(html)
      end
    end

    describe "members property with role and functions in JSON format" do
      it "should IssuesHelper#show_detail with no_html should show a changing enabled members" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"],"functions":[]}', :value => '{"name":"user1","roles":["Developer", "Manager"],"functions":["function1"]}', :prop_key => 'member_roles_and_functions')
        expect(show_detail(detail, true)).to eq "Member user1 has been changed with roles from [Developer] to [Developer, Manager] and functions from [] to [function1]"
      end

      it "should IssuesHelper#show_detail with no_html should show a changing roles only" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"],"functions":["function1"]}', :value => '{"name":"user1","roles":["Developer", "Manager"],"functions":["function1"]}', :prop_key => 'member_roles_and_functions')
        expect(show_detail(detail, true)).to eq "Member user1 has been changed with roles from [Developer] to [Developer, Manager]"
      end

      it "should IssuesHelper#show_detail with no_html should show a changing functions onlu" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"],"functions":[]}', :value => '{"name":"user1","roles":["Developer"],"functions":["function1"]}', :prop_key => 'member_roles_and_functions')
        expect(show_detail(detail, true)).to eq "Member user1 has been changed with functions from [] to [function1]"
      end

      it "should IssuesHelper#show_detail with no_html should show a deleted members" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"],"functions":["function1"]}', :value => nil, :prop_key => 'member_roles_and_functions')
        expect(show_detail(detail, true)).to eq "Member user1, with roles [Developer] and functions [function1], has been removed"
      end

      it "should IssuesHelper#show_detail with no_html should show a deleted members without functions" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"],"functions":[]}', :value => nil, :prop_key => 'member_roles_and_functions')
        expect(show_detail(detail, true)).to eq "Member user1, with roles [Developer], has been removed"
      end

      it "should IssuesHelper#show_detail with html should show a new member with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => nil, :value => '{"name":"user1","roles":["Developer"],"functions":["function2"]}', :prop_key => 'member_roles_and_functions')
        detail.id = 1
        result = show_detail(detail, false)
        expect(result).to eq("Member user1 has been added with roles [Developer] and functions [function2]")
      end

      it "should IssuesHelper#show_detail with html should show a deleted members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => '{"name":"user1","roles":["Developer"],"functions":["function2"]}', :value => nil, :prop_key => 'member_roles_and_functions')
        html = show_detail(detail, false)
        expect(html).to eq("Member user1, with roles [Developer] and functions [function2], has been removed")
      end

      it "should IssuesHelper#show_detail with html should show all new members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value => nil, :value =>  '{"name":"user1","roles":["Developer", "Manager"],"functions":["function3"]}', :prop_key => 'member_roles_and_functions')
        detail.id = 1
        result = show_detail(detail, false)
        html = "Member user1 has been added with roles [Developer, Manager] and functions [function3]"
        expect(result).to eq(html)
      end

      it "should IssuesHelper#show_detail with html should show all deleted members with HTML highlights" do
        detail = JournalDetail.new(:property => 'members', :old_value =>  '{"name":"user1","roles":["Developer", "Manager"],"functions":["function1","function2"]}', :value => nil, :prop_key => 'member_roles_and_functions')
        result = show_detail(detail, false)
        html = "Member user1, with roles [Developer, Manager] and functions [function1, function2], has been removed"
        expect(result).to eq(html)
      end
    end
  end

  describe "copy project" do
    it "should IssuesHelper#copy_project with no_html should show the source project" do
      detail = JournalDetail.new(:property => 'copy_project', :value => "Test (id: 4)", :prop_key => 'copy_project') 
      expect(show_detail(detail, true)).to eq "Project copy from Test (id: 4)"
    end

    it "should IssuesHelper#copy_project with html should show the source project with HTML highlights" do
      detail = JournalDetail.new(:property => 'copy_project', :value => "Test (id: 4)", :prop_key => 'copy_project')
      result = show_detail(detail, false)      
      html = "Project copy from Test (id: 4)"
      expect(result).to include(html)
    end
  end

  describe "status project" do

    it "should IssuesHelper#show_detail with no_html should show the property status followed by changing it from closed to active" do
      detail = JournalDetail.new(:property => 'status', :old_value => "5", :value => "1", :prop_key => 'status')
      expect(show_detail(detail, true)).to eq "Status changed from closed to active"
    end

    it "should IssuesHelper#show_detail with html should show the property status with HTML highlights followed by changing it from closed to active" do
      detail = JournalDetail.new(:property => 'status', :old_value => "5", :value => "1", :prop_key => 'status')      
      result = show_detail(detail, false)
      html = "changed from closed to active"
      expect(result).to include(html)      
    end

    it "should IssuesHelper#show_detail with no_html should show the property status followed by changing it from active to closed" do
      detail = JournalDetail.new(:property => 'status', :old_value => "1", :value => "5", :prop_key => 'status')
      expect(show_detail(detail, true)).to eq "Status changed from active to closed" 
    end

    it "should IssuesHelper#show_detail with html should show the property status with HTML highlights followed by changing it from active to closed" do
      detail = JournalDetail.new(:property => 'status', :old_value => "1", :value => "5", :prop_key => 'status')
      result = show_detail(detail, false)
      html = "changed from active to closed"
      expect(result).to include(html)
    end

    it "should IssuesHelper#show_detail with no_html should show the property status followed by changing it from active to archived" do
      detail = JournalDetail.new(:property => 'status', :old_value => "1", :value => "9", :prop_key => 'status')
      expect(show_detail(detail, true)).to eq "Status changed from active to archived" 
    end

    it "should IssuesHelper#show_detail with html should show the property status with HTML highlights followed by changing it from active to archived" do
      detail = JournalDetail.new(:property => 'status', :old_value => "1", :value => "9", :prop_key => 'status')
      result = show_detail(detail, false)
      html = "changed from active to archived"
      expect(result).to include(html)      
    end

    it "should IssuesHelper#show_detail with no_html should show the property status followed by changing it from archived to active" do
      detail = JournalDetail.new(:property => 'status', :old_value => "9", :value => "1", :prop_key => 'status')
      expect(show_detail(detail, true)).to eq "Status changed from archived to active"
    end

    it "should IssuesHelper#show_detail with html should show the property status with HTML highlights followed by changing it from archived to active" do
      detail = JournalDetail.new(:property => 'status', :old_value => "9", :value => "1", :prop_key => 'status')
      result = show_detail(detail, false)
      html = "changed from archived to active"
      expect(result).to include(html)
    end

    it "should IssuesHelper#show_detail with no_html should show the property status of project archived when one of it ancestor is closed followed by changing it from archived to closed" do
      detail = JournalDetail.new(:property => 'status', :old_value => "9", :value => "5", :prop_key => 'status')
      expect(show_detail(detail, true)).to eq "Status changed from archived to closed"    
    end

    it "should IssuesHelper#show_detail with html should show the property status (with HTML highlights) of project archived when one of it ancestor is closed followed by changing it from archived to closed" do
      detail = JournalDetail.new(:property => 'status', :old_value => "9", :value => "5", :prop_key => 'status')
      result = show_detail(detail, false)
      html = "changed from archived to closed"
      expect(result).to include(html)      
    end
  end

end
