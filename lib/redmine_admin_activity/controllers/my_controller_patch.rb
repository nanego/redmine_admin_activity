require_dependency 'my_controller'

module RedmineAdminActivity::Controllers
  module MyControllerPatch
    extend ActiveSupport::Concern

    def capture_my_account_state
      return unless User.current.logged?

      @previous_user_mail = User.current.mail
      @previous_user_hashed_password = User.current.hashed_password
      @previous_user_profile = {
        'login'     => User.current.login,
        'firstname' => User.current.firstname,
        'lastname'  => User.current.lastname
      }
    end

    def init_my_account_journal
      return unless User.current.logged?

      User.current.init_journal(User.current)
    end

    def journalized_my_account_update
      return unless request.put? && User.current.logged?

      user = User.current
      return unless user.present? && user.persisted?
      return unless @previous_user_profile.present?

      all_changes = {}
      @previous_user_profile.each do |field, prev_val|
        curr_val = user.send(field)
        all_changes[field] = [prev_val, curr_val] if prev_val != curr_val
      end

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
      return unless @previous_user_hashed_password != user.hashed_password

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

  before_action :capture_my_account_state, :only => [:account, :password]
  before_action :init_my_account_journal, :only => [:account, :password]
  after_action :journalized_my_account_update, :only => [:account]
  after_action :journalized_my_password_change, :only => [:password]
end
