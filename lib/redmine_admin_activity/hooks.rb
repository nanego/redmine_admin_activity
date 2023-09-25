# frozen_string_literal: true

module RedmineAdminActivity
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        require_relative 'controllers/concerns/journalizable'

        require_relative 'controllers/projects_controller' # unless Rails.env.test?
        require_relative 'controllers/issue_categories_controller'
        require_relative 'controllers/members_controller'
        require_relative 'controllers/principal_memberships_controller'
        require_relative 'controllers/trackers_controller'
        require_relative 'controllers/custom_fields_controller'
        require_relative 'controllers/settings_controller'
        require_relative 'controllers/custom_field_enumerations_controller'
        require_relative 'controllers/wiki_controller'

        if Redmine::Plugin.installed?(:redmine_organizations)
          require_relative 'controllers/organizations/memberships_controller'
          require_relative 'controllers/organizations_controller'
          require_relative 'models/organization'
        end

        require_relative 'controllers/users_controller'

        require_relative 'models/project'
        require_relative 'models/member'
        require_relative 'models/journal'
        require_relative 'models/version'
        require_relative 'models/custom_field'
        require_relative 'models/user'
        require_relative 'models/issue_template' if Redmine::Plugin.installed?(:redmine_templates)

        require_relative 'helpers/projects_helper'
        require_relative 'helpers/issues_helper'
        require_relative 'helpers/settings_helper'
      end
    end
  end
end
