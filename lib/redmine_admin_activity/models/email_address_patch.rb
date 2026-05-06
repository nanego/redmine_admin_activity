# frozen_string_literal: true

require_dependency 'email_address'

module RedmineAdminActivity::Models
  module EmailAddressPatch
    def self.included(base)
      base.after_create  :journalize_addition
      base.after_destroy :journalize_removal
    end

    private

    def journalize_addition
      return if is_default?
      journalize_email_change(old_value: nil, new_value: address)
    end

    def journalize_removal
      return if is_default?
      journalize_email_change(old_value: address, new_value: nil)
    end

    def journalize_email_change(old_value:, new_value:)
      return unless user.present?

      # In auto-provisioning contexts User.current may be anonymous — fall back to the user itself
      author = User.current&.logged? ? User.current : user

      JournalSetting.create(
        user_id:                author.id,
        value_changes:          { 'mails' => [old_value, new_value] },
        journalized:            user,
        journalized_entry_type: "update"
      )

      user.init_journal(author)
      user.current_journal.details << JournalDetail.new(
        property:  'attr',
        prop_key:  'mails',
        old_value: old_value,
        value:     new_value
      )
      user.current_journal.save
    end
  end
end

class EmailAddress
  include RedmineAdminActivity::Models::EmailAddressPatch
end
