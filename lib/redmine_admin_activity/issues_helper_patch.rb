require_dependency 'issues_helper'
require 'json'

module PluginAdminActivity
  module IssuesHelper

    # Returns the textual representation of a single journal detail
    # Core properties are 'attr', 'attachment' or 'cf' : this patch specify how to display 'modules' journal details
    # 'modules' property is introduced by this plugin
    def show_detail(detail, no_html = false, options = {})
      case detail.property
      when 'modules'
        show_modules_details(detail, no_html, options)
      when 'members'
        show_members_details(detail, no_html, options)
      when 'issue_category'
        show_issue_category_details(detail, no_html, options)
      when 'trackers'
        show_trackers_details(detail, no_html, options)
      when 'custom_fields'
        show_custom_fields_details(detail, no_html, options)
      when 'copy_project'
        show_copy_project_details(detail, no_html, options)
      else
        # Process standard properties like 'attr', 'attachment' or 'cf'
        super
      end
    end

    private

    def show_modules_details(detail, no_html = false, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_modules_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
      new_values = new_values.any? ? l(:text_journal_modules_added, :value => new_values.join(', ')).html_safe : ""

      l(:text_journal_modules_changed, :deleted => deleted_values, :new => new_values).html_safe
    end

    def show_members_details(detail, no_html = false, options = {})
      case detail.prop_key
      when 'member_with_roles'
        value = JSON.parse(detail.value || "{}")
        old_value = JSON.parse(detail.old_value || "{}")
        name = value["name"] || old_value["name"]
        new_roles = value.fetch("roles", []).join(", ")
        old_roles = old_value.fetch("roles", []).join(", ")

        if value.present? && old_value.present?
          l(:text_journal_member_changed, :name => name, :new => new_roles, :old => old_roles).html_safe
        elsif value.present? && old_value.empty?
          l(:text_journal_member_added, :name => name, :new => new_roles).html_safe
        else
          l(:text_journal_member_removed, :name => name, :old => old_roles).html_safe
        end

      when 'member_roles_and_functions'
        value = JSON.parse(detail.value || "{}")
        old_value = JSON.parse(detail.old_value || "{}")
        name = value["name"] || old_value["name"]
        new_roles = value.fetch("roles", []).join(", ")
        old_roles = old_value.fetch("roles", []).join(", ")
        new_functions = value.fetch("functions", []).join(", ")
        old_functions = old_value.fetch("functions", []).join(", ")

        changes = []

        if value.present? && old_value.present?
          changes << l(:text_journal_member_roles_changed, :old => old_roles, :new => new_roles) if (new_roles.present? || old_roles.present?) && old_roles != new_roles
          changes << l(:text_journal_member_functions_changed, :old => old_functions, :new => new_functions) if (new_functions.present? || old_functions.present?) && old_functions != new_functions
          changes = changes.join(" #{l(:and)} ")

          l(:text_journal_member_with_roles_and_functions_changed, :name => name, :changes => changes).html_safe
        elsif value.present? && old_value.empty?
          changes << l(:text_journal_member_roles, :roles => new_roles) if new_roles.present?
          changes << l(:text_journal_member_functions, :functions => new_functions) if new_functions.present?
          changes = changes.join(" #{l(:and)} ")

          l(:text_journal_member_with_roles_and_functions_added, :name => name, :changes => changes).html_safe
        else
          changes << l(:text_journal_member_roles, :roles => old_roles) if old_roles.present?
          changes << l(:text_journal_member_functions, :functions => old_functions) if old_functions.present?
          changes = changes.join(" #{l(:and)} ")

          l(:text_journal_member_with_roles_and_functions_removed, :name => name, :changes => changes).html_safe
        end

      else
        value = string_list_to_array(detail.value)
        old_value = string_list_to_array(detail.old_value)
        deleted_values = old_value - value
        new_values = value - old_value

        deleted_values = deleted_values.any? ? l(:text_journal_members_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
        new_values = new_values.any? ? l(:text_journal_members_added, :value => new_values.join(', ')).html_safe : ""

        l(:text_journal_members_changed, :deleted => deleted_values, :new => new_values).html_safe

      end
    end

    def show_issue_category_details(detail, no_html = false, options = {})
      value = detail.value
      old_value = detail.old_value
      data = {:old_value => old_value, :value => value}

      if value.present? && old_value.present?
        l(:text_journal_issue_category_changed, data)
      elsif value.present? && old_value.blank?
        l(:text_journal_issue_category_added, data)
      elsif value.blank? && old_value.present?
        l(:text_journal_issue_category_removed, data)
      end.html_safe
    end

    def show_trackers_details(detail, no_html = false, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_trackers_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
      new_values = new_values.any? ? l(:text_journal_trackers_added, :value => new_values.join(', ')).html_safe : ""

      l(:text_journal_trackers_changed, :deleted => deleted_values, :new => new_values).html_safe
    end

    def show_custom_fields_details(detail, no_html = false, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_custom_fields_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
      new_values = new_values.any? ? l(:text_journal_custom_fields_added, :value => new_values.join(', ')).html_safe : ""

      l(:text_journal_custom_fields_changed, :deleted => deleted_values, :new => new_values).html_safe
    end

    def show_copy_project_details(detail, no_html = false, options = {})
      l(:text_journal_copy_project, :value => detail.value).html_safe
    end

    def string_list_to_array(value)
      return [] if value.blank?

      value.split(",")
    end
  end
end

IssuesHelper.prepend PluginAdminActivity::IssuesHelper
ActionView::Base.prepend IssuesHelper
