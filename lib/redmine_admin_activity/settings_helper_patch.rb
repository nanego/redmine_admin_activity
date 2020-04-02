require_dependency 'settings_helper'

module RedmineAdminActivity

  module SettingsHelper

    def administration_settings_tabs
      tabs = super
      admin_activity_tab = {name: 'admin_activity', action: :admin_activity, partial: 'settings/admin_activity', label: :project_module_admin_activity}
      if tabs.size > 1
        tabs.insert(2, admin_activity_tab)
      else
        tabs << admin_activity_tab
      end
      tabs
    end

  end

end

SettingsHelper.prepend RedmineAdminActivity::SettingsHelper
ActionView::Base.send(:include, SettingsHelper)
