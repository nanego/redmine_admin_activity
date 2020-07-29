require_dependency 'principal_memberships_controller'

class PrincipalMembershipsController
  include RedmineAdminActivity::Journalizable

  before_action :store_role_ids, :only => [:destroy]
  after_action :journalized_memberships_creation, :only => [:create]
  after_action :journalized_memberships_deletion, :only => [:destroy]

  private

  def store_role_ids
    member = Member.find(params[:id])
    @previous_role_ids = member.role_ids
    @previous_function_ids = member.function_ids if limited_visibility_plugin_installed?
  end

  def journalized_memberships_creation
    @members.each do |member|
      next unless member.persisted?
      role_ids = params[:membership][:role_ids]
      function_ids = params[:membership][:function_ids] if limited_visibility_plugin_installed?
      add_member_creation_to_journal(member, role_ids, function_ids)
    end
  end

  def journalized_memberships_deletion
    add_member_deletion_to_journal(@membership, @previous_role_ids, @previous_function_ids)
  end
end
