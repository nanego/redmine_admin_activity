require_dependency 'issues_helper'

module IssuesHelper
  unless instance_methods.include?(:show_detail_with_admin_activity)

    # Returns the textual representation of a single journal detail
    # Core properties are 'attr', 'attachment' or 'cf' : this patch specify how to display 'modules' journal details
    # 'modules' property is introduced by this plugin
    def show_detail_with_admin_activity(detail, no_html=false, options={})

      # Process custom 'projects' property
      if detail.property == 'modules'

        value = detail.value.split(',')
        old_value = detail.old_value.split(',')
        deleted_values = old_value - value
        new_values = value - old_value

        deleted_values = deleted_values.any? ? l(:text_journal_modules_removed, :value => deleted_values.join(', '), :and => (new_values.any? ? 'et' : '')).html_safe : ""
        new_values = new_values.any? ? l(:text_journal_modules_added, :value => new_values.join(', ')).html_safe : ""

        l(:text_journal_modules_changed, :deleted => deleted_values, :new => new_values).html_safe

      else
        # Process standard properties like 'attr', 'attachment' or 'cf'
        show_detail_without_admin_activity(detail, no_html, options)
      end

    end
    alias_method_chain :show_detail, :admin_activity
  end
end
