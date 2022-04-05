ActiveSupport::Reloader.to_prepare do
  require_dependency 'redmine_admin_activity/controllers/concerns/journalizable'

  require_dependency 'redmine_admin_activity/controllers/projects_controller' # unless Rails.env.test?
  require_dependency 'redmine_admin_activity/controllers/issue_categories_controller'
  require_dependency 'redmine_admin_activity/controllers/members_controller'
  require_dependency 'redmine_admin_activity/controllers/principal_memberships_controller'
  require_dependency 'redmine_admin_activity/controllers/trackers_controller'
  require_dependency 'redmine_admin_activity/controllers/custom_fields_controller'
  require_dependency 'redmine_admin_activity/controllers/settings_controller'

  if Redmine::Plugin.installed?(:redmine_organizations)
    require_dependency 'redmine_admin_activity/controllers/organizations/memberships_controller'
    require_dependency 'redmine_admin_activity/controllers/organizations_controller'
    require_dependency 'redmine_admin_activity/models/organization'
  end

  require_dependency 'redmine_admin_activity/controllers/users_controller'
  
  require_dependency 'redmine_admin_activity/models/project'
  require_dependency 'redmine_admin_activity/models/member'
  require_dependency 'redmine_admin_activity/models/journal'
  require_dependency 'redmine_admin_activity/models/version'
  require_dependency 'redmine_admin_activity/models/user'

  require_dependency 'redmine_admin_activity/helpers/projects_helper'
  require_dependency 'redmine_admin_activity/helpers/issues_helper'
  require_dependency 'redmine_admin_activity/helpers/settings_helper'
  require_dependency 'redmine_admin_activity/helpers/journal_settings_helper'
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
