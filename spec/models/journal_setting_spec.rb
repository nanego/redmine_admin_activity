require "spec_helper"

RSpec.describe JournalSetting, type: :model do

  fixtures :projects, :users, :custom_fields, :journals

  if Redmine::Plugin.installed?(:redmine_organizations)
    fixtures :organizations
  end

  let(:journal_setting) { described_class.new(:value_changes => { "name" => ["old_value", "value"] },
                                              :user_id => 1) }

  context "with valid attributes" do
    it { expect(journal_setting).to be_valid }
  end

  context "without a user" do
    it { expect(described_class.new(:value_changes => { "name" => ["old_value", "value"] })).not_to be_valid }
  end

  context "without value_changes" do
    it { expect(described_class.new(:user_id => 1)).not_to be_valid }
  end

  describe "scope search_scope" do

    before do
      project = projects(:projects_001)
      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "name" => ["eCookbook", nil] },
                                   :journalized => project,
                                   :journalized_entry_type => "destroy")
      journal.save

      if Redmine::Plugin.installed?(:redmine_organizations)
        org = Organization.new(:name => "Org test", :parent_id => Organization.last.id)
        org.save

        journal = JournalSetting.new(:user_id => User.current.id,
                                     :value_changes => { "name" => [nil, org.name], "name_with_parents" => [nil, org.fullname] },
                                     :journalized => org,
                                     :journalized_entry_type => "create")  
        journal.save
      end

      field = CustomField.new(:name => "test field",
                              :type => "IssueCustomField",
                              :field_format => "string")
      field.save

      journal = JournalSetting.new(:user_id => User.current.id,
                                    :value_changes => { "name" => ["", field.name], "field_format" => ["", "string"] },
                                    :journalized_id => field.id,
                                    :journalized_type => "IssueCustomField",
                                    :journalized_entry_type => "create")
      journal.save

      user = User.new(:login => 'newuser',
                      :firstname => 'test',
                      :lastname => 'user',
                      :mail => 'newuser@example.net'
      )
      user.save

      journal = JournalSetting.new(:user_id => User.current.id,
                                   :value_changes => { "login" => ["", "newuser"], "firstname" => ["", "test"], "lastname" => ["", "user"] },
                                   :journalized => user,
                                   :journalized_entry_type => "create")

      journal.save

    end


    it "Shows all when field is empty" do
      if Redmine::Plugin.installed?(:redmine_organizations)
        expect(JournalSetting.search_scope('').count).to eq(4)
      else
        expect(JournalSetting.search_scope('').count).to eq(3)
      end
    end

    it "Shows journal filtered by field case-insensitive" do
      if Redmine::Plugin.installed?(:redmine_organizations)
        expect(JournalSetting.search_scope('TEst').count).to eq(3)
      else
        expect(JournalSetting.search_scope('TEst').count).to eq(2)
      end
    end

    it "Shows journal filtered by field first name + last name case of (user)" do
      expect(JournalSetting.search_scope('est use').count).to eq(1)
    end

    it "Shows no journal when name does not exist" do
      expect(JournalSetting.search_scope('toto').count).to eq(0)
    end
  end
end
