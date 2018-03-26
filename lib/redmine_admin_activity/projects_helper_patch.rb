require_dependency 'projects_helper'

module RedmineAdminActivity

  module ProjectsHelper

    def project_settings_tabs
      tabs = super
      unregistered_watchers_tab = {name: 'admin_activity', action: :admin_activity, partial: 'projects/admin_activity', label: :project_module_admin_activity}
      tabs.insert(2, unregistered_watchers_tab)
      tabs
    end

  end

end

ProjectsHelper.prepend RedmineAdminActivity::ProjectsHelper
ActionView::Base.send(:include, ProjectsHelper)
