module PluginAdminActivity
  module JournalSettingsHelper

    def settings_update_text(name, changes)
      field_name = l("setting_#{name}")
      field_name = l("label_theme") if name == "ui_theme"

      sanitize l(".text_setting_journal_entry", field:  field_name, old_value: changes[0], value: changes[1])
    end

    def project_update_text(journal)
      if journal.creation? || journal.duplication? || journal.activation? || journal.closing? || journal.archivation? || journal.reopening?
        project_text = link_to_project_if_exists(journal.journalized) || name_project_if_not_exists(journal)

        return sanitize l(".text_setting_create_project_journal_entry", project: project_text) if journal.creation?
        return sanitize l(".text_setting_active_project_journal_entry", project: project_text) if journal.activation?
        if journal.closing?
          return sanitize l(".text_setting_change_from_archive_to_close_project_journal_entry", project: project_text) if journal.value_changes["status"][0] == Project::STATUS_ARCHIVED
          return sanitize l(".text_setting_close_project_journal_entry", project: project_text)
        end        
        return sanitize l(".text_setting_archive_project_journal_entry", project: project_text) if journal.archivation?
        return sanitize l(".text_setting_reopen_project_journal_entry", project: project_text) if journal.reopening?

        source_project = Project.find_by(id: journal.value_changes["source_project"])
        source_project_text = link_to_project_if_exists(source_project) || journal.value_changes["source_project_name"]

        sanitize l(".text_setting_copy_project_journal_entry", project: project_text,
                                                               source_project: source_project_text)
      elsif journal.deletion?
        sanitize l(".text_setting_destroy_project_journal_entry", project_name: journal.value_changes["name"][0])
      end
    end

    def user_update_text(journal)
      if journal.creation? || journal.activation? || journal.locking? || journal.unlocking?
        user_text = link_to_user_if_exists(journal.journalized) || name_user_if_not_exists(journal)

        return sanitize l(".text_setting_create_user_journal_entry", user: user_text) if journal.creation?
        return sanitize l(".text_setting_active_user_journal_entry", user: user_text) if journal.activation?
        return sanitize l(".text_setting_lock_user_journal_entry", user: user_text) if journal.locking?
        return sanitize l(".text_setting_unlock_user_journal_entry", user: user_text) if journal.unlocking?

      elsif journal.deletion?
        sanitize l(".text_setting_destroy_user_journal_entry", user_name: journal.value_changes["firstname"][0] + " " + journal.value_changes["lastname"][0])
      end
    end

    private

    def link_to_project_if_exists(project)
      link_to(project.name, project_path(project)) if project.present? && project.persisted?
    end

    def link_to_user_if_exists(user)
      link_to(user.name, user_path(user)) if user.present? && user.persisted?
    end

    def name_project_if_not_exists(journal)      
      journal_row_destroy = JournalSetting.find_by journalized_id: journal.journalized_id, journalized_entry_type: 'destroy'
      journal_row_destroy.value_changes["name"][0]
    end

    def name_user_if_not_exists(journal)
        
      journal_row_destroy = JournalSetting.find_by journalized_id: journal.journalized_id, journalized_entry_type: 'destroy'
      journal_row_destroy.value_changes["firstname"][0] + " " + journal_row_destroy.value_changes["lastname"][0]
    end

    ActionView::Base.send :include, JournalSettingsHelper
  end
end
