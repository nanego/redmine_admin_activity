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
        show_modules_details(detail, options)
      when 'members'
        show_members_details(detail, options)
      when 'issue_category'
        show_issue_category_details(detail, options)
      when 'versions'
        show_versions_details(detail, options)
      when 'trackers'
        show_trackers_details(detail, options)
      when 'templates'
        show_templates_details(detail, options)
      when 'custom_fields'
        show_custom_fields_details(detail, options)
      when 'copy_project'
        show_copy_project_details(detail, options)
      when 'status'
        show_project_status_details(detail, no_html, options)
      when 'functions'
        show_functions_details(detail, options)
      else
        if detail.property != 'cf' && detail.journal.present? && detail.journal.journalized_type == 'Principal'
          details = show_principal_detail(detail, no_html, options)
          details ? details : super
        else
          # Process standard properties like 'attr', 'attachment' or 'cf'
          super
        end
      end
    end

    private

    def show_modules_details(detail, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_modules_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')) : ""
      new_values = new_values.any? ? l(:text_journal_modules_added, :value => new_values.join(', ')) : ""

      l(:text_journal_modules_changed, :deleted => deleted_values, :new => new_values)
    end

    def show_functions_details(detail, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_functions_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')) : ""
      new_values = new_values.any? ? l(:text_journal_functions_added, :value => new_values.join(', ')) : ""

      l(:text_journal_functions_changed, :deleted => deleted_values, :new => new_values)
    end

    def show_members_details(detail, options = {})
      case detail.prop_key
      when 'member_with_roles'
        value = JSON.parse(detail.value || "{}")
        old_value = JSON.parse(detail.old_value || "{}")
        name = value["name"] || old_value["name"]
        new_roles = value.fetch("roles", []).join(", ")
        old_roles = old_value.fetch("roles", []).join(", ")

        if value.present? && old_value.present?
          l(:text_journal_member_changed, :name => name, :new => new_roles, :old => old_roles)
        elsif value.present? && old_value.empty?
          l(:text_journal_member_added, :name => name, :new => new_roles)
        else
          l(:text_journal_member_removed, :name => name, :old => old_roles)
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

          l(:text_journal_member_with_roles_and_functions_changed, :name => name, :changes => changes)
        elsif value.present? && old_value.empty?
          changes << l(:text_journal_member_roles, :roles => new_roles) if new_roles.present?
          changes << l(:text_journal_member_functions, :functions => new_functions) if new_functions.present?
          changes = changes.join(" #{l(:and)} ")

          l(:text_journal_member_with_roles_and_functions_added, :name => name, :changes => changes)
        else
          changes << l(:text_journal_member_roles, :roles => old_roles) if old_roles.present?
          changes << l(:text_journal_member_functions, :functions => old_functions) if old_functions.present?
          changes = changes.join(" #{l(:and)} ")

          l(:text_journal_member_with_roles_and_functions_removed, :name => name, :changes => changes)
        end

      else
        value = string_list_to_array(detail.value)
        old_value = string_list_to_array(detail.old_value)
        deleted_values = old_value - value
        new_values = value - old_value

        deleted_values = deleted_values.any? ? l(:text_journal_members_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')) : ""
        new_values = new_values.any? ? l(:text_journal_members_added, :value => new_values.join(', ')) : ""

        l(:text_journal_members_changed, :deleted => deleted_values, :new => new_values)

      end
    end

    def show_issue_category_details(detail, options = {})
      value = detail.value
      old_value = detail.old_value
      data = { :old_value => old_value, :value => value }

      if value.present? && old_value.present?
        l(:text_journal_issue_category_changed, data)
      elsif value.present? && old_value.blank?
        l(:text_journal_issue_category_added, data)
      elsif value.blank? && old_value.present?
        l(:text_journal_issue_category_removed, data)
      end
    end

    def show_versions_details(detail, options = {})
      value = detail.value
      old_value = detail.old_value
      data = { :old_value => old_value, :value => value }

      if value.present? && old_value.present?
        l(:text_journal_version_changed, data)
      elsif value.present? && old_value.blank?
        l(:text_journal_version_added, data)
      elsif value.blank? && old_value.present?
        l(:text_journal_version_removed, data)
      end
    end

    def show_trackers_details(detail, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_trackers_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')) : ""
      new_values = new_values.any? ? l(:text_journal_trackers_added, :value => new_values.join(', ')) : ""

      l(:text_journal_trackers_changed, :deleted => deleted_values, :new => new_values)
    end

    def show_templates_details(detail, options = {})
      value = string_list_to_array(detail.value)
      case detail.prop_key
      when 'enabled_template'
        return l(:text_journal_templates_enabled, :value => value)
      end
    end

    def show_custom_fields_details(detail, options = {})
      value = string_list_to_array(detail.value)
      old_value = string_list_to_array(detail.old_value)
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_custom_fields_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')) : ""
      new_values = new_values.any? ? l(:text_journal_custom_fields_added, :value => new_values.join(', ')) : ""

      l(:text_journal_custom_fields_changed, :deleted => deleted_values, :new => new_values)
    end

    def show_copy_project_details(detail, options = {})
      l(:text_journal_copy_project, :value => detail.value)
    end

    def show_project_status_details(detail, no_html, options = {})
      label = no_html ? l(:text_label_status) : content_tag('strong', l(:text_label_status))
      value = get_project_status_label_for_history[detail.value]
      old_value = get_project_status_label_for_history[detail.old_value]
      l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
    end

    def show_user_status_details(detail, no_html , options = {})
      label = no_html ? l(:text_label_status) : content_tag('strong', l(:text_label_status))
      value = get_user_status_label_for_history[detail.value]
      old_value = get_user_status_label_for_history[detail.old_value]
      l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
    end

    def get_project_status_label_for_history
      {
        Project::STATUS_ACTIVE.to_s => l(:project_status_active),
        Project::STATUS_CLOSED.to_s => l(:project_status_closed),
        Project::STATUS_ARCHIVED.to_s => l(:project_status_archived),
      }
    end

    def get_user_status_label_for_history
      {
        User::STATUS_ANONYMOUS.to_s => l(:label_user_anonymous),
        User::STATUS_ACTIVE.to_s => l(:status_active),
        User::STATUS_REGISTERED.to_s => l(:status_registered),
        User::STATUS_LOCKED.to_s => l(:status_locked),
      }
    end

    def string_list_to_array(value)
      return [] if value.blank?

      value.split(",")
    end

    def show_associations_details(klass_name, key, value, old_value, no_html = false , options = {})
      klazz = Object.const_get(klass_name)
      association_class = klazz.reflect_on_all_associations(:has_many).select { |a| a.name.to_s == key }.first.klass
      label_class_name = "label_#{association_class.name.downcase}"
      val = association_class.find_by(:id => value)
      old_val = association_class.find_by(:id => old_value)

      if value.present?
        label_new = val.present? ? val.to_s : l(:label_id_deleted, :id => value)

        return l(:text_journal_association_added, :class_name => l(label_class_name), :new => label_new)
      elsif old_value.present?
        label_old = old_val.present? ? old_val.to_s : l(:label_id_deleted, :id => old_value)

        return l(:text_journal_association_deleted, :class_name => l(label_class_name), :old => label_old)
      end
    end

    def show_has_and_belongs_to_many_details(klass_name, key, value, old_value, no_html = false , options = {})
      klazz = Object.const_get(klass_name)
      association_class = klazz.reflect_on_all_associations(:has_and_belongs_to_many).select { |a| a.name.to_s == key }.first.klass
      label_class_name = "label_#{association_class.name.downcase}_plural"
      val = association_class.where(:id => value)
      old_val = association_class.where(:id => old_value)

      # If the value is deleted and journalized, try to search it in the journalsetting table(journal_row_destroy) else set Id
      #In the future (when all models will be traced, we can use the function name_journalized_if_not_exists instead of ids)
      deleted_ids = (value - val.map(&:id)).map { |s| name_journalized_if_not_exists(association_class.name, s) || s.to_s.prepend('#') }
      old_deleted_ids = (old_value - old_val.map(&:id)).map { |s| name_journalized_if_not_exists(association_class.name, s) || s.to_s.prepend('#') }

      return l(:text_journal_has_and_belongs_to_many_changed,
        :class_name => l(label_class_name),
        :new => (val.map(&:to_s) + deleted_ids).join(", "),
        :old => (old_val.map(&:to_s) + old_deleted_ids).join(", "))
    end

    def show_has_many_details(klass_name, key, value, old_value, no_html = false , options = {})
      klazz = Object.const_get(klass_name)
      association_class = klazz.reflect_on_all_associations(:has_many).select { |a| a.name.to_s == key }.first.klass
      label_class_name = "label_#{association_class.name.downcase}"

      val = association_class.where(:id => value)
      old_val = association_class.where(:id => old_value)

      deleted_ids = (value - val.map(&:id)).map { |s| s.to_s.prepend('#') }
      old_deleted_ids = (old_value - old_val.map(&:id)).map { |s| s.to_s.prepend('#') }

      return l(:text_journal_has_many_changed,
        :class_name => l(label_class_name),
        :new => (val.map(&:to_s) + deleted_ids).join(", "),
        :old => (old_val.map(&:to_s) + old_deleted_ids).join(", "))
    end

    def show_belongs_to_details(klass_name, key, value, old_value, no_html = false , options = {})
      klazz = Object.const_get(klass_name)
      belongs_to_class = klazz.reflect_on_all_associations(:belongs_to).select{ |a| a.foreign_key == key }.first.klass
      label_class_name = "label_#{belongs_to_class.name.downcase}"
      val = belongs_to_class.find_by(:id => value)
      old_val = belongs_to_class.find_by(:id => old_value)

      if value.present? && old_value.present?
        label_new = val.present? ? val.to_s : l(:label_id_deleted, :id => value)
        label_old = old_val.present? ? old_val.to_s : l(:label_id_deleted, :id => old_value)

        return l(:text_journal_belongs_to_changed, :class_name => l(label_class_name), :new => label_new, :old => label_old)
      elsif value.present?
        label_new = val.present? ? val.to_s : l(:label_id_deleted, :id => value)

        return l(:text_journal_belongs_to_added, :class_name => l(label_class_name), :new => label_new)
      elsif old_value.present?
        label_old = old_val.present? ? old_val.to_s : l(:label_id_deleted, :id => old_value)

        return l(:text_journal_belongs_to_deleted, :class_name => l(label_class_name), :old => label_old)
      end
    end

    def show_boolean_details(key, value, old_value, no_html = false , options = {})
      field = key.to_s.gsub(/\_id$/, "")
      label = l(("field_" + field).to_sym)
      l(:text_journal_changed, :label => label, :old => val_to_bool(old_value) ? l(:label_1) : l(:label_0), :new => val_to_bool(value) ? l(:label_1) : l(:label_0))
    end

    def show_principal_detail(detail, no_html , options = {})
      if detail.prop_key == 'status'
        show_user_status_details(detail, no_html, options)
      elsif detail.property == 'associations'
        if User.reflect_on_all_associations(:has_many).select { |a| a.name.to_s == detail.prop_key }.count > 0
          show_associations_details("User", detail.prop_key, detail.value, detail.old_value, no_html, options)
        end
      elsif detail.property == 'attr'
        if User.reflect_on_all_associations(:belongs_to).select{ |a| a.foreign_key == detail.prop_key }.count > 0
          show_belongs_to_details("User", detail.prop_key, detail.value, detail.old_value, no_html, options)
        elsif User.columns_hash[detail.prop_key].present? && User.columns_hash[detail.prop_key].type == :boolean
          show_boolean_details(detail.prop_key, detail.value, detail.old_value, no_html, options)
        end
      end
    end

    def val_to_bool(val)
      return val if val.in? [true, false]
      return !val.to_i.zero? if val.class.in? [String, Integer]
    end
  end
end

IssuesHelper.prepend PluginAdminActivity::IssuesHelper
ActionView::Base.prepend IssuesHelper
