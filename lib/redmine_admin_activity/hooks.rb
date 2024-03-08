# frozen_string_literal: true

module RedmineAdminActivity
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        require_relative 'journalizable'

        require_relative 'controllers/projects_controller_patch'
        require_relative 'jobs/destroy_project_job_patch'
        require_relative 'controllers/issue_categories_controller_patch'
        require_relative 'controllers/members_controller_patch'
        require_relative 'controllers/principal_memberships_controller_patch'
        require_relative 'controllers/trackers_controller_patch'
        require_relative 'controllers/custom_fields_controller_patch'
        require_relative 'controllers/settings_controller_patch'
        require_relative 'controllers/custom_field_enumerations_controller_patch'
        require_relative 'controllers/wiki_controller_patch'

        if Redmine::Plugin.installed?(:redmine_organizations)
          require_relative 'controllers/organizations/memberships_controller_patch'
          require_relative 'controllers/organizations_controller_patch'
          require_relative 'models/organization_patch'
        end

        require_relative 'controllers/users_controller_patch'

        require_relative 'models/project_patch'
        require_relative 'models/member_patch'
        require_relative 'models/journal_patch'
        require_relative 'models/version_patch'
        require_relative 'models/custom_field_patch'
        require_relative 'models/user_patch'
        require_relative 'models/issue_template_patch' if Redmine::Plugin.installed?(:redmine_templates)

        require_relative 'helpers/projects_helper_patch'
        require_relative 'helpers/issues_helper_patch'
        require_relative 'helpers/settings_helper_patch'
      end
    end
  end
end
