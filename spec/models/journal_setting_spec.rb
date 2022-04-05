require "spec_helper"

RSpec.describe JournalSetting, type: :model do
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
end
