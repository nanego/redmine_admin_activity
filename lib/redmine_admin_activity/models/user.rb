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
    excluded_names = User.column_names - %w(login firstname lastname admin status organization_id sudoer staff beta_tester instance_manager issue_display_mode trusted_api_user)
    names = User.column_names - excluded_names + ["mails"]
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

end
