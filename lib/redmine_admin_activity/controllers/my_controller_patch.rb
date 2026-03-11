require_dependency 'my_controller'

module RedmineAdminActivity::Controllers
  module MyControllerPatch
    extend ActiveSupport::Concern

    def capture_my_account_state
      return unless request.put? && User.current.logged?

      @previous_user_mail = User.current.mail
    end

    def init_my_account_journal
      return unless User.current.logged?

      User.current.init_journal(User.current)
    end

    def journalized_my_account_update
      return unless request.put? && User.current.logged?

      user = User.current
      return unless user.present? && user.persisted?

      tracked_columns = %w(login firstname lastname)
      all_changes = user.previous_changes.select { |k, _| tracked_columns.include?(k) }

      # Email change
      current_mail = user.mail
      if @previous_user_mail != current_mail
        all_changes['mails'] = [Array(@previous_user_mail).to_s, Array(current_mail).to_s]
      end

      return if all_changes.empty?

      JournalSetting.create(
        :user_id => user.id,
        :value_changes => all_changes,
        :journalized => user,
        :journalized_entry_type => "update"
      )

      user.current_journal&.save
    end

    def journalized_my_password_change
      return unless User.current.logged?

      user = User.current
      return unless user.present? && user.persisted?
      return unless user.previous_changes.key?('hashed_password')

      JournalSetting.create(
        :user_id => user.id,
        :value_changes => { 'hashed_password' => [nil, nil] },
        :journalized => user,
        :journalized_entry_type => "update"
      )

      if user.current_journal
        user.current_journal.details << JournalDetail.new(
          :property => 'attr',
          :prop_key => 'hashed_password',
          :old_value => nil,
          :value => nil
        )
        user.current_journal.save
      end
    end
  end
end

class MyController
  include RedmineAdminActivity::Controllers::MyControllerPatch

  before_action :capture_my_account_state, :only => [:account]
  before_action :init_my_account_journal, :only => [:account, :password]
  after_action :journalized_my_account_update, :only => [:account]
  after_action :journalized_my_password_change, :only => [:password]
end
