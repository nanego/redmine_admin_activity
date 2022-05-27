require_relative 'lib/redmine_admin_activity/hooks'
  require_dependency 'redmine_admin_activity/controllers/custom_field_enumerations_controller'
    require_dependency 'redmine_admin_activity/models/organization'
  require_dependency 'redmine_admin_activity/models/custom_field'

Redmine::Plugin.register :redmine_admin_activity do
  name 'Redmine Admin Activity plugin'
  author 'Vincent ROBERT'
  description 'This plugin keeps a log of all admin actions'
  version '4.0.0'
  url 'https://github.com/nanego/redmine_admin_activity'
  permission :see_project_activity, {  }

  # requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end
