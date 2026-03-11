require_dependency 'users_controller'

module RedmineAdminActivity::Controllers
  module UsersControllerPatch
    extend ActiveSupport::Concern
    include Redmine::Pagination

    def history
      @scope = get_journal_for_history(@user.journals)
      @journal_count = @scope.count
      @journal_pages = Paginator.new @journal_count, per_page_option, params['page']
      @journals = @scope.limit(@journal_pages.per_page).offset(@journal_pages.offset).to_a
      @journals = add_index_to_journal_for_history(@journals)
    end

    def journalized_users_creation

      return unless @user.present? && @user.persisted?

      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => @user.previous_changes,
        :journalized => @user,
        :journalized_entry_type => "create",
        )
      add_journal_entry_for_user(user: @user, property: 'creation', prop_key: 'creation', value: User::USER_MANUAL_CREATION)
    end

    def journalized_users_update_status

      return unless @user.present? && @user.persisted?

      if @user.previous_changes[:status] == [User::STATUS_REGISTERED, User::STATUS_ACTIVE]
        JournalSetting.create(
          :user_id => User.current.id,
          :value_changes => @user.previous_changes,
          :journalized => @user,
          :journalized_entry_type => "active",
          )
      end

      if @user.previous_changes[:status] == [User::STATUS_ACTIVE, User::STATUS_LOCKED]
        JournalSetting.create(
          :user_id => User.current.id,
          :value_changes => @user.previous_changes,
          :journalized => @user,
          :journalized_entry_type => "lock",
          )
      end

      if @user.previous_changes[:status] == [User::STATUS_LOCKED, User::STATUS_ACTIVE]
        JournalSetting.create(
          :user_id => User.current.id,
          :value_changes => @user.previous_changes,
          :journalized => @user,
          :journalized_entry_type => "unlock",
          )
      end

    end

    def journalized_users_deletion
      return unless @user.destroyed?

      changes = @user.attributes.to_a.map { |i| [i[0], [i[1], nil]] }.to_h
      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => changes,
        :journalized => @user,
        :journalized_entry_type => "destroy",
        )
    end

    def capture_user_state_before_update
      return unless @user.present?

      @previous_user_mail = @user.mail
    end

    def journalized_users_update
      return unless @user.present? && @user.persisted?

      # Track fields for JournalSetting (global history)
      tracked_columns = %w(login firstname lastname status)
      tracked_columns << (Redmine::Plugin.installed?(:redmine_sudo) ? 'sudoer' : 'admin')
      tracked_columns |= %w(staff beta_tester instance_manager trusted_api_user) if Redmine::Plugin.installed?(:redmine_scn)

      all_changes = @user.previous_changes.select { |k, _| tracked_columns.include?(k) }

      # Password change: hide the actual hash values
      all_changes['hashed_password'] = [nil, nil] if @user.previous_changes.key?('hashed_password')

      # Email change: compare main mail
      current_mail = @user.mail
      if @previous_user_mail != current_mail
        all_changes['mails'] = [Array(@previous_user_mail).to_s, Array(current_mail).to_s]
      end

      # Organization change
      if Redmine::Plugin.installed?(:redmine_organizations) && @user.previous_changes.key?('organization_id')
        old_org_id, new_org_id = @user.previous_changes['organization_id']
        old_org = old_org_id ? Organization.find_by(:id => old_org_id)&.to_s : nil
        new_org = new_org_id ? Organization.find_by(:id => new_org_id)&.to_s : nil
        all_changes['organization'] = [old_org, new_org]
      end

      return if all_changes.empty?

      # JournalSetting for global history: exclude status (already tracked by journalized_users_update_status)
      js_changes = all_changes.reject { |k, _| k == 'status' }
      if js_changes.any?
        JournalSetting.create(
          :user_id => User.current.id,
          :value_changes => js_changes,
          :journalized => @user,
          :journalized_entry_type => "update"
        )
      end

      # JournalDetails for user-specific history:
      # Only special cases here (e.g. masked password).
      if @user.current_journal
        if @user.previous_changes.key?('hashed_password')
          @user.current_journal.details << JournalDetail.new(
            :property => 'attr',
            :prop_key => 'hashed_password',
            :old_value => nil,
            :value => nil
          )
        end
        @user.current_journal.save
      end
    end

    def init_journal
      @user.init_journal(User.current)
    end
  end
end

class UsersController
  include RedmineAdminActivity::Controllers::UsersControllerPatch

  helper :journal_settings
  include JournalSettingsHelper
  include RedmineAdminActivity::Journalizable

  after_action :journalized_users_creation, :only => [:create]
  after_action :journalized_users_update_status, :only => [:update]
  after_action :journalized_users_update, :only => [:update]
  after_action :journalized_users_deletion, :only => [:destroy]
  before_action :capture_user_state_before_update, :only => [:update]
  before_action :init_journal, :only => [:update]
  before_action lambda { find_user(false) }, :only => :history

end
