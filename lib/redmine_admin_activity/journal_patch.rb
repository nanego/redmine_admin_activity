require_dependency 'journal'

module RedmineAdminActivity

  module Journal

    def send_notification
      # Do not send any notification after create project's journals
      super unless journalized.class == Project
    end

  end

end

Journal.prepend RedmineAdminActivity::Journal
