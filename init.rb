require_relative 'lib/redmine_admin_activity/hooks'

Redmine::Plugin.register :redmine_admin_activity do
  name 'Redmine Admin Activity plugin'
  author 'Vincent ROBERT'
  description 'This plugin keeps a log of all admin actions'
  version '4.0.0'
  url 'https://github.com/nanego/redmine_admin_activity'
  permission :see_project_activity, {  }

  # requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end
