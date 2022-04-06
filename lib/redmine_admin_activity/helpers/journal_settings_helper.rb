module PluginAdminActivity
  module JournalSettingsHelper

    def prepare_journal_for_history(journals)
      journals = journals.includes(:user, :details).
        references(:user, :details).
        reorder(:created_on, :id).to_a
      journals.each_with_index { |j, i| j.indice = i + 1 }
      Journal.preload_journals_details_custom_fields(journals)
      journals.select! { |journal| journal.notes? || journal.visible_details.any? }
      journals.reverse! # Last changes first
    end

    def settings_update_text(name, changes)
      field_name = l("setting_#{name}")
      field_name = l("label_theme") if name == "ui_theme"

      sanitize l(".text_setting_journal_entry", field: field_name, old_value: changes[0], value: changes[1])
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

    def organization_update_text(journal)
      if journal.creation?
        organization_text = link_to_organization_if_exists(journal.journalized) || name_organization_if_not_exists(journal)
        return sanitize l(".text_setting_create_organization_journal_entry", organization: organization_text) if journal.creation?
      elsif journal.deletion?
        return sanitize l(".text_setting_destroy_organization_journal_entry", organization_name: journal.value_changes["name_with_parents"][0])
      elsif journal.updating?
          organization_text = link_to_organization_if_exists(journal.journalized) || name_organization_if_not_exists(journal)
          s = sanitize l(".text_setting_update_organization_journal_entry", organization: organization_text) if journal.updating?
          content = ''
          if journal.value_changes.any?
            content += content_tag(:ul, :class => 'details') do
              journal_setting_to_strings(journal).collect do |item|
                content_tag(:li, item)
              end.reduce(&:+)
            end
          end

          return s += content.html_safe
      end
    end

    def custom_field_update_text(journal)
      if journal.creation?
        custom_field_text = link_to_custom_field_if_exists(journal.journalized) || name_custom_field_if_not_exists(journal)
        return sanitize l(".text_setting_create_custom_field_journal_entry", custom_field: custom_field_text) if journal.creation?
      elsif journal.deletion?
        return sanitize l(".text_setting_destroy_custom_field_journal_entry", custom_field: journal.value_changes["name"][0])
      elsif journal.updating?
          custom_field_text = link_to_custom_field_if_exists(journal.journalized) || name_custom_field_if_not_exists(journal)
          s = sanitize l(".text_setting_update_custom_field_journal_entry", custom_field: custom_field_text) if journal.updating?
          content = ''
          if journal.value_changes.any?
            content += content_tag(:ul, :class => 'details') do
              journal_setting_to_strings(journal).collect do |item|
                content_tag(:li, item)
              end.reduce(&:+)
            end
          end

          return s += content.html_safe
      end
    end

    private

    def link_to_project_if_exists(project)
      link_to(project.name, project_path(project)) if project.present? && project.persisted?
    end

    def name_project_if_not_exists(journal)
      journal_row_destroy = JournalSetting.find_by journalized_id: journal.journalized_id, journalized_type: journal.journalized_type, journalized_entry_type: 'destroy'
      journal_row_destroy.value_changes["name"][0]      
    end

    def link_to_user_if_exists(user)
      link_to(user.name, user_path(user)) if user.present? && user.persisted?
    end

    def name_user_if_not_exists(journal)
        
      journal_row_destroy = JournalSetting.find_by journalized_id: journal.journalized_id, journalized_type: journal.journalized_type, journalized_entry_type: 'destroy'
      journal_row_destroy.value_changes["firstname"][0] + " " + journal_row_destroy.value_changes["lastname"][0]
    end

    def link_to_organization_if_exists(organization)
      link_to(organization.fullname, organization_path(organization)) if organization.present? && organization.persisted?
    end

    def name_organization_if_not_exists(journal)
      journal_row_destroy = JournalSetting.find_by journalized_id: journal.journalized_id, journalized_type: journal.journalized_type , journalized_entry_type: 'destroy'
      journal_row_destroy.value_changes["name_with_parents"][0]
    end

    def link_to_custom_field_if_exists(custom_field)
      link_to(custom_field.name, edit_custom_field_path(custom_field)) if custom_field.present? && custom_field.persisted?
    end

    def name_custom_field_if_not_exists(journal)
      journal_row_destroy = JournalSetting.find_by journalized_id: journal.journalized_id, journalized_type: journal.journalized_type , journalized_entry_type: 'destroy'
      journal_row_destroy.value_changes["name"][0]
    end

    # Returns the textual representation of a journal details
    # as an array of strings
    def journal_setting_to_strings(journal)
      strings = []
      klazz = Object.const_get(journal.journalized_type)
      journal.value_changes.each do |value|
        if klazz.reflect_on_all_associations(:belongs_to).select{ |a| a.foreign_key == value[0] }.count > 0
          strings << show_belongs_to_details(journal.journalized_type, value[0], value[1][1], value[1][0])
        # If we want to treat associations many_to_many
        #elsif klazz.reflect_on_all_associations(:has_many).select{ |a| a.foreign_key == value[0] }.count > 0
          #strings << show_associations_details(journal.journalized_type, value[0], value[1][1], value[1][0])
        elsif klazz.reflect_on_all_associations(:has_and_belongs_to_many).select{ |a| a.name == value[0].to_sym }.count > 0
          strings << show_has_and_belongs_to_many_details(journal.journalized_type, value[0], value[1][1], value[1][0])
        else
          type = klazz.columns_hash[value[0]].type
          case type
          when :boolean
            strings << show_boolean_details(value[0], value[1][1], value[1][0])
          #when ,if we want to treat another type
          else
            strings << show_details_by_default(value)
          end
        end
      end
      strings
    end

    # Returns the textual representation of a single journal setting by default
    def show_details_by_default(detail)
      label = l(("field_" + detail[0]).to_sym)
      l(:text_journal_changed, :label => label, :old => detail[1].first, :new => detail[1].second)
    end

    ActionView::Base.send :include, JournalSettingsHelper
  end
end
