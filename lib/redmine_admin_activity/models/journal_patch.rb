require_dependency 'journal'

module RedmineAdminActivity::Models

  module JournalPatch

    def send_notification
      # Do not send any notification after create project's or user's journals
      return if journalized.class == Project || journalized.class == User
      super
    end

    def add_watcher
      # Auto-watching only applies to issue journals
      return unless journalized.is_a?(Issue)
      super
    end

  end

end

Journal.prepend RedmineAdminActivity::Models::JournalPatch
