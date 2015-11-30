require_dependency 'projects_helper'

module ProjectsHelper

  unless instance_methods.include?(:project_settings_tabs_with_admin_activity)
    def project_settings_tabs_with_admin_activity
      tabs = project_settings_tabs_without_admin_activity
      unregistered_watchers_tab = {name: 'admin_activity', action: :admin_activity, partial: 'projects/admin_activity', label: :project_module_admin_activity}
      tabs.insert(2, unregistered_watchers_tab)
      tabs
    end
    alias_method_chain :project_settings_tabs, :admin_activity
  end

end
