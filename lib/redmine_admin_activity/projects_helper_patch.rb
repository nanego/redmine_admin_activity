require_dependency 'projects_helper'

module RedmineAdminActivity

  module ProjectsHelper

    def project_settings_tabs
      tabs = super
      admin_activity_tab = {name: 'admin_activity', action: :admin_activity, partial: 'projects/admin_activity', label: :project_module_admin_activity}
      if tabs.size > 1
        tabs.insert(2, admin_activity_tab)
      else
        tabs << admin_activity_tab
      end
      tabs
    end

  end

end

ProjectsHelper.prepend RedmineAdminActivity::ProjectsHelper
ActionView::Base.send(:include, ProjectsHelper)
