require_dependency 'journal'

module RedmineAdminActivity

  module Journal

    def send_notification
      # Do not send any notification after create project's or user's journals
      return if journalized.class == Project || journalized.class == User
      super
    end

  end

end

Journal.prepend RedmineAdminActivity::Journal
