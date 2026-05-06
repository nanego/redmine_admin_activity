require 'rails_helper'

describe EmailAddress, type: :model do
  fixtures :users, :email_addresses

  let(:admin) { User.find(1) }
  let(:user) { User.find(2) }

  before { User.current = admin }

  describe "adding a secondary email address" do
    it "creates a JournalSetting entry" do
      expect {
        EmailAddress.create!(user: user, address: 'secondary@example.com', is_default: false)
      }.to change(JournalSetting, :count).by(1)

      js = JournalSetting.last
      expect(js.journalized).to eq(user)
      expect(js.journalized_entry_type).to eq("update")
      expect(js.value_changes['mails']).to eq([nil, 'secondary@example.com'])
    end

    it "creates a JournalDetail on the user" do
      expect {
        EmailAddress.create!(user: user, address: 'secondary@example.com', is_default: false)
      }.to change(JournalDetail, :count).by(1)

      detail = JournalDetail.last
      expect(detail.prop_key).to eq('mails')
      expect(detail.old_value).to be_nil
      expect(detail.value).to eq('secondary@example.com')
    end

    it "does not journalize changes to the default address" do
      expect {
        EmailAddress.create!(user: user, address: 'other@example.com', is_default: true)
      }.not_to change(JournalSetting, :count)
    end
  end

  describe "removing a secondary email address" do
    let!(:secondary) { EmailAddress.create!(user: user, address: 'todelete@example.com', is_default: false) }

    it "creates a JournalSetting entry" do
      expect {
        secondary.destroy
      }.to change(JournalSetting, :count).by(1)

      js = JournalSetting.last
      expect(js.journalized).to eq(user)
      expect(js.value_changes['mails']).to eq(['todelete@example.com', nil])
    end
  end

  describe "with anonymous User.current" do
    before { User.current = User.anonymous }

    it "falls back to the user itself as journal author" do
      EmailAddress.create!(user: user, address: 'auto@example.com', is_default: false)
      js = JournalSetting.last
      expect(js.user_id).to eq(user.id)
    end
  end
end
