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
  after_action :journalized_users_deletion, :only => [:destroy]
  before_action :init_journal, :only => [:update]
  before_action lambda { find_user(false) }, :only => :history

end
