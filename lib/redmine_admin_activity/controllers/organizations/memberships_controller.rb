require_dependency 'organizations/memberships_controller'

class Organizations::MembershipsController
  include RedmineAdminActivity::Journalizable

  before_action :store_previous_values, :only => [:update]
  after_action :journalized_memberships_edition, :only => [:update]
  after_action :journalized_non_members_roles_creation, :only => [:create_non_members_roles]

  before_action :store_previous_values_non_members_roles, :only => [:update_non_members_roles, :destroy_non_members_roles, :update_non_members_functions]
  after_action :journalized_non_members_roles_edition, :only => [:update_non_members_roles]
  after_action :journalized_non_members_functions_edition, :only => [:update_non_members_functions]
  after_action :add_non_members_deletion_to_journal, :only => [:destroy_non_members_roles]
  after_action :add_non_members_deletion_to_journal, :only => [:destroy_non_members_roles]

  private

  def store_previous_values
    @requested_users = User.where(id: params[:membership][:user_ids].reject(&:empty?))
    @requested_roles = Role.where(id: params[:membership][:role_ids].reject(&:empty?))
    @previous_current_users = @organization.users_by_project(@project)

    @new_users = @requested_users - @previous_current_users
    to_be_deleted_users = @previous_current_users - @requested_users
    to_be_deleted_members = Member.where(user: to_be_deleted_users, project: @project)
    to_be_deleted_members = to_be_deleted_members.includes(:functions) if limited_visibility_plugin_installed?
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
    journalize_deleted_users
  end

  def journalize_new_users(organization_functions, previous_organization_functions)
    @new_users.each do |user|
      member = Member.where(user: user, project: @project).first_or_initialize

      if limited_visibility_plugin_installed?
        personal_functions = member.functions - previous_organization_functions
        function_ids = (organization_functions | personal_functions).map { |f| f.id }
      end

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

        next if (previous_role_ids.sort == role_ids.sort) && (previous_function_ids.sort == function_ids.sort)
      else
        next if (previous_role_ids.sort == role_ids.sort)
      end

      add_member_edition_to_journal(member, previous_role_ids, role_ids, previous_function_ids, function_ids)
    end
  end

  def journalize_deleted_users
    @deletable_members.each do |member|
      previous_function_ids = member.function_ids if limited_visibility_plugin_installed?
      add_member_deletion_to_journal(member, member.role_ids, previous_function_ids)
    end
  end

  def journalized_non_members_roles_creation
    if @organization.present? && @organization.persisted?
      add_member_exception_creation_to_journal(@current_organization_roles, @current_organization_roles.role.id)
    end
  end

  def store_previous_values_non_members_roles
    @previous_roles_ids = OrganizationNonMemberRole.where(project_id: @project.id, organization_id: @organization.id).map(&:role_id)
    @previous_functions_ids = []
    @previous_functions_ids = OrganizationNonMemberFunction.where(project_id: @project.id, organization_id: @organization.id).map(&:function_id) if Redmine::Plugin.installed?(:redmine_limited_visibility)
    @member_exception = OrganizationNonMemberRole.where(project_id: @project.id, organization_id: @organization.id).first
  end

  def journalized_non_members_roles_edition
    new_roles_ids = params[:membership][:role_ids].reject(&:empty?).map(&:to_i)
    add_member_exception_edition_roles_to_journal(@member_exception, @previous_roles_ids, new_roles_ids)
  end

  def journalized_non_members_functions_edition
    new_functions_ids = params[:membership][:function_ids].reject(&:empty?).map(&:to_i)
    add_member_exception_edition_functions_to_journal(@member_exception, @previous_functions_ids, new_functions_ids)
  end

  def add_non_members_deletion_to_journal
    add_member_exception_deletion_to_journal(@member_exception, @previous_roles_ids, @previous_functions_ids)
  end
end
