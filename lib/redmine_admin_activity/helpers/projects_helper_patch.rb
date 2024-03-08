require_dependency 'projects_helper'

module RedmineAdminActivity::Helpers

  module ProjectsHelperPatch

    def project_settings_tabs
      tabs = super
      if User.current.allowed_to?(:see_project_activity, @project)
        admin_activity_tab = {name: 'admin_activity', action: :admin_activity, partial: 'projects/admin_activity', label: :project_module_admin_activity}
        if tabs.size > 1
          tabs.insert(2, admin_activity_tab)
        else
          tabs << admin_activity_tab
        end
      end
      tabs
    end

  end

end

ProjectsHelper.prepend RedmineAdminActivity::Helpers::ProjectsHelperPatch
ActionView::Base.send(:include, ProjectsHelper)
