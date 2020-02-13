require_dependency 'issues_helper'

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
      else
        # Process standard properties like 'attr', 'attachment' or 'cf'
        super
      end
    end

    private

    def show_modules_details(detail, no_html = false, options = {})
      if detail.value.present?
        value = detail.value.split(',')
      else
        value = []
      end
      if detail.old_value.present?
        old_value = detail.old_value.split(',')
      else
        old_value = []
      end
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_modules_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
      new_values = new_values.any? ? l(:text_journal_modules_added, :value => new_values.join(', ')).html_safe : ""

      l(:text_journal_modules_changed, :deleted => deleted_values, :new => new_values).html_safe
    end

    def show_members_details(detail, no_html = false, options = {})
      if detail.value.present?
        value = detail.value.split(',')
      else
        value = []
      end
      if detail.old_value.present?
        old_value = detail.old_value.split(',')
      else
        old_value = []
      end
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_members_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
      new_values = new_values.any? ? l(:text_journal_members_added, :value => new_values.join(', ')).html_safe : ""

      l(:text_journal_members_changed, :deleted => deleted_values, :new => new_values).html_safe
    end

    def show_issue_category_details(detail, no_html = false, options = {})
      if detail.value.present?
        value = detail.value.split(',')
      else
        value = []
      end
      if detail.old_value.present?
        old_value = detail.old_value.split(',')
      else
        old_value = []
      end
      deleted_values = old_value - value
      new_values = value - old_value

      deleted_values = deleted_values.any? ? l(:text_journal_issue_category_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? l(:and) : '')).html_safe : ""
      new_values = new_values.any? ? l(:text_journal_issue_category_added, :value => new_values.join(', ')).html_safe : ""

      l(:text_journal_issue_category_changed, :deleted => deleted_values, :new => new_values).html_safe
    end
  end
end

IssuesHelper.prepend PluginAdminActivity::IssuesHelper
ActionView::Base.prepend IssuesHelper
