require_dependency 'organizations/memberships_controller'

class Organizations::MembershipsController
  include RedmineAdminActivity::Journalizable

  before_action :store_previous_values, :only => [:update]
  after_action :journalized_memberships_edition, :only => [:update]

  private

  def store_previous_values
    @requested_users = User.where(id: params[:membership][:user_ids].reject(&:empty?))
    @requested_roles = Role.where(id: params[:membership][:role_ids].reject(&:empty?))
    @previous_current_users = @organization.users_by_project(@project)

    @new_users = @requested_users - @previous_current_users
    to_be_deleted_users = @previous_current_users - @requested_users
    to_be_deleted_members = Member.where(user: to_be_deleted_users, project: @project)
    @deletable_members = to_be_deleted_members.select { |m| (m.roles & User.current.managed_roles(@project)) == m.roles }

    @updated_members = @previous_current_users.map do |u|
      query = Member.includes(:roles)
      query = query.includes(:functions) if limited_visibility_plugin_installed?
      query.find_by(user: u, project: @project)
    end.reject { |m| @deletable_members.include?(m) }

    if limited_visibility_plugin_installed?
      @previous_organization_functions_ids = @organization.default_functions_by_project(@project).map { |f| f.id }
    end
  end

  def journalized_memberships_edition
    if limited_visibility_plugin_installed?
      organization_functions = @organization.organization_functions.where(project_id: @project.id).map(&:function).reject(&:blank?)
      previous_organization_functions = @organization.default_functions_by_project(@project)
    end
    journalize_new_users(organization_functions, previous_organization_functions)
    journalize_updated_users(organization_functions, previous_organization_functions)
    journalize_deleted_users(organization_functions, previous_organization_functions)
  end

  def journalize_new_users(organization_functions, previous_organization_functions)
    @new_users.each do |user|
      member = Member.where(user: user, project: @project).first_or_initialize

      personal_functions = member.functions - previous_organization_functions
      function_ids = (organization_functions | personal_functions).map { |f| f.id }

      add_member_creation_to_journal(member, @requested_roles.ids, function_ids)
    end
  end

  def journalize_updated_users(organization_functions, previous_organization_functions)
    @updated_members.each do |member|
      function_ids = nil
      previous_function_ids = nil

      previous_role_ids = member.roles.ids
      if limited_visibility_plugin_installed?
        previous_function_ids = member.functions.ids
      end

      member.reload
      role_ids = Member.includes(:roles).find_by(user: member.user, project: @project).roles.ids

      if limited_visibility_plugin_installed?
        personal_functions = member.functions - previous_organization_functions
        function_ids = (organization_functions | personal_functions).map { |f| f.id }

        next if previous_role_id.difference(role_ids).empty? && previous_function_ids.difference(function_ids).empty?
      else
        next if previous_role_id.difference(role_ids).empty?
      end

      add_member_edition_to_journal(member, previous_role_ids, role_ids, previous_function_ids, function_ids)
    end
  end

  def journalize_deleted_users(organization_functions, previous_organization_functions)
    @deletable_members.each do |member|
      previous_function_ids = nil

      if limited_visibility_plugin_installed?
        previous_function_ids = member.functions.ids
      end

      add_member_deletion_to_journal(member, member.role_ids, previous_function_ids)
    end
  end

end
