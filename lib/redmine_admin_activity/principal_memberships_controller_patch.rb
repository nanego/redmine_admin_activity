require_dependency 'principal_memberships_controller'

class PrincipalMembershipsController
  include RedmineAdminActivity::ControllerHelpers

  before_action :store_role_ids, :only => [:update]
  after_action :journalized_memberships_creation, :only => [:create]
  after_action :journalized_memberships_upgrade, :only => [:update]
  after_action :journalized_memberships_deletion, :only => [:destroy]

  private

  def store_role_ids
    member = Member.find(params[:id])
    @previous_role_ids = member.role_ids
    @previous_function_ids = member.function_ids if installed_plugin?(:redmine_limited_visibility)
  end

  def journalized_memberships_creation
    entries = []

    if params[:membership]
      project_ids = Array.wrap(params[:membership][:project_id] || params[:membership][:project_ids])
      project_ids << nil if project_ids.empty?
      Project.where(id: project_ids).each do |project|
        user_id = params[:membership][:role_id]
        role_ids = params[:membership][:role_ids]
        member = Member.new(:project => project, :user_id => user_id)
        member.set_editable_role_ids(role_ids)

        if installed_plugin?(:redmine_limited_visibility)
          function_ids = params[:membership][:function_ids]

          add_journal_entry project, JournalDetail.new(
            :property => 'members',
            :prop_key => 'member_roles_and_functions',
            :value    => {
              :name => @principal.to_s,
              :roles => Role.where(id: role_ids).pluck(:name),
              :functions => Function.where(id: function_ids).pluck(:name)
            }.to_json
          )
        else
          add_journal_entry project, JournalDetail.new(
            :property => 'members',
            :prop_key => 'member_with_roles',
            :value    => { :name => @principal.to_s, :roles => Role.where(id: role_ids).pluck(:name) }.to_json
          )
        end
      end
    end
  end

  def journalized_memberships_upgrade
    return if @previous_role_ids == @member.roles.ids

    previous_roles = Role.where(id: @previous_role_ids).pluck(:name)
    new_roles = Role.where(id: @member.roles.ids).pluck(:name)

    if installed_plugin?(:redmine_limited_visibility) # &&
      previous_functions = Function.where(id: @previous_function_ids).pluck(:name)
      new_functions = Function.where(id: @member.functions.ids).pluck(:name)

      add_journal_entry @project, JournalDetail.new(
        :property  => :members,
        :prop_key  => 'member_roles_and_functions',
        :old_value => {
          :name => @principal.to_s,
          :roles => previous_roles,
          :functions => previous_functions,
        }.to_json,
        :value     => {
          :name => @principal.to_s,
          :roles => new_roles,
          :functions => new_functions,
        }.to_json
      )
    else
      add_journal_entry @project, JournalDetail.new(
        :property  => :members,
        :prop_key  => 'member_with_roles',
        :old_value => { :name => @principal.to_s, :roles => previous_roles }.to_json,
        :value     => { :name => @principal.to_s, :roles => new_roles }.to_json
      )
    end
  end

  # Called after a member is removed
  def journalized_memberships_deletion
    project = @membership.project

    if installed_plugin?(:redmine_limited_visibility)
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_roles_and_functions',
        :old_value => {
          :name => @principal.to_s,
          :roles => Role.where(id: @membership.roles.ids).pluck(:name),
          :functions => Function.where(id: @membership.functions.ids).pluck(:name)
        }.to_json
      )
    else
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_with_roles',
        :old_value => { :name => @membership.to_s, :roles => Role.where(id: @membership.roles.ids).pluck(:name) }.to_json
      )
    end
  end
end
