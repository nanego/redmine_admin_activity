module RedmineAdminActivity::ControllerHelpers
  # Store a [JournalDetail] or an array of [JournalDetail]s in a new
  # journal entry for current User.
  def add_journal_entry(project, journal_details)
    project.init_journal(User.current)

    journal_details = [journal_details] unless journal_details.is_a?(Array)
    project.current_journal.details = journal_details

    project.current_journal.save
  end

  def installed_plugin?(name)
    Redmine::Plugin.installed?(name)
  end
end
