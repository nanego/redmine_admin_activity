require_dependency 'user'

class User < Principal

	has_many :JournalSetting, :dependent => :nullify

	has_many :journals, :as => :journalized, :dependent => :destroy, :inverse_of => :journalized

	attr_reader :current_journal

	after_save :create_journal

	def init_journal(user)
		@current_journal ||= Journal.new(:journalized => self, :user => user)
	end

	# Returns the current journal or nil if it's not initialized
  def current_journal
    @current_journal
  end

  # Returns the names of attributes that are journalized when updating the user
  def journalized_attribute_names
    names = %w(login firstname lastname status mails)
    names << 'organization' if Redmine::Plugin.installed?(:redmine_organizations)
    names << (Redmine::Plugin.installed?(:redmine_sudo) ? 'sudoer' : 'admin')
    names |= %w(staff beta_tester instance_manager issue_display_mode trusted_api_user) if Redmine::Plugin.installed?(:redmine_scn)
    names
  end

	def create_journal
		if current_journal
			current_journal.save
		end
	end

  def notified_users
    []
  end

  def notified_watchers
    []
  end

  def self.representative_columns
    return "firstname" , "lastname"
  end

  def self.representative_link_path(obj)
    Rails.application.routes.url_helpers.user_url(obj, only_path: true)
  end

end
