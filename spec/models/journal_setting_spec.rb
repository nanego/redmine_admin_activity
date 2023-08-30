require "spec_helper"

RSpec.describe JournalSetting, type: :model do

  fixtures :projects, :users, :custom_fields, :journals
  fixtures :organizations if Redmine::Plugin.installed?(:redmine_organizations)

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

  describe "JournalSetting search_scope" do

    let!(:project_journal) { JournalSetting.create(:user_id => User.current.id,
                                                   :value_changes => { "name" => ["eCookbook", nil] },
                                                   :journalized => projects(:projects_001),
                                                   :journalized_entry_type => "destroy") }

    let!(:new_custom_field) { CustomField.create(:name => "test field",
                                                 :type => "IssueCustomField",
                                                 :field_format => "string") }
    let!(:new_custom_field_journal) { JournalSetting.create(:user_id => User.current.id,
                                                            :value_changes => { "name" => ["", new_custom_field.name], "field_format" => ["", "string"] },
                                                            :journalized => new_custom_field,
                                                            :journalized_entry_type => "create") }

    let!(:user) { User.create(:login => 'newuser',
                              :firstname => 'test',
                              :lastname => 'user',
                              :mail => 'newuser@example.net') }
    let!(:user_journal) { JournalSetting.create(:user_id => User.current.id,
                                                :value_changes => { "login" => ["", "newuser"], "firstname" => ["", "test"], "lastname" => ["", "user"] },
                                                :journalized => user,
                                                :journalized_entry_type => "create") }

    context "without scope" do
      it "shows all entries when search field is empty" do
        expect(JournalSetting.search_scope('').size).to eq(3)
      end
    end

    it "shows journals filtered by field case-insensitive" do
      results = JournalSetting.search_scope('TEst')
      expect(results.size).to eq(2)
      expect(results).to_not include(project_journal)
    end

    it "shows journals filtered by user firstname + lastname" do
      results = JournalSetting.search_scope('est use')
      expect(results.size).to eq(1)
      expect(results.first).to eq(user_journal)
    end

    it "shows journals filtered by custom-field name" do
      results = JournalSetting.search_scope('test field')
      expect(results.size).to eq(1)
      expect(results.first).to eq(new_custom_field_journal)
    end

    it "shows no journal when name does not exist" do
      expect(JournalSetting.search_scope('toto').size).to eq(0)
    end

    if Redmine::Plugin.installed?(:redmine_organizations)
      context "plugin organizations is installed" do

        let!(:new_organization) { Organization.create(:name => "Org test", :parent_id => Organization.last.id) }
        let!(:new_organization_journal) { JournalSetting.create(:user_id => User.current.id,
                                                                :value_changes => { "name" => [nil, new_organization.name], "name_with_parents" => [nil, new_organization.fullname] },
                                                                :journalized => new_organization,
                                                                :journalized_entry_type => "create") }

        it "shows journals filtered by organization name" do
          expect(JournalSetting.search_scope('').size).to eq(4)
          expect(JournalSetting.search_scope('TEst')).to include(new_organization_journal)
        end

      end
    end

  end
end
