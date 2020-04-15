ActiveSupport::Reloader.to_prepare do
  require_dependency 'redmine_admin_activity/projects_controller_patch' # unless Rails.env.test?
  require_dependency 'redmine_admin_activity/project_patch'
  require_dependency 'redmine_admin_activity/projects_helper_patch'
  require_dependency 'redmine_admin_activity/issue_categories_controller_patch'
  require_dependency 'redmine_admin_activity/issues_helper_patch'
  require_dependency 'redmine_admin_activity/member_patch'
  require_dependency 'redmine_admin_activity/members_controller_patch'
  require_dependency 'redmine_admin_activity/journal_patch'
  require_dependency 'redmine_admin_activity/trackers_controller_patch'
  require_dependency 'redmine_admin_activity/custom_fields_controller_patch'
  require_dependency 'redmine_admin_activity/settings_controller_patch'
  require_dependency 'redmine_admin_activity/settings_helper_patch'
  require_dependency 'redmine_admin_activity/journal_settings_helper'
end

Redmine::Plugin.register :redmine_admin_activity do
  name 'Redmine Admin Activity plugin'
  author 'Vincent ROBERT'
  description 'This plugin keeps a log of all admin actions'
  version '4.0.0'
  url 'https://github.com/nanego/redmine_admin_activity'
  permission :see_project_activity, {  }
  # requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end
