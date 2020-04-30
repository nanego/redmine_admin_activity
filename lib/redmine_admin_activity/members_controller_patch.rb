require_dependency 'members_controller'

class MembersController
  include RedmineAdminActivity::ControllerHelpers

  before_action :store_role_ids, :only => [:update, :destroy]
  after_action :journalized_members_creation, :only => [:create]
  after_action :journalized_members_upgrade, :only => [:update]
  after_action :journalized_member_deletion, :only => [:destroy]

  private

  def store_role_ids
    member = Member.find(params[:id])
    @previous_role_ids = member.role_ids
    @previous_function_ids = member.function_ids if installed_plugin?(:redmine_limited_visibility)
  end

  def journalized_members_creation
    entries = []

    if params[:membership]
      user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids])
      user_ids << nil if user_ids.empty?
      user_ids.each do |user_id|
        role_ids = params[:membership][:role_ids]
        member = Member.new(:project => @project, :user_id => user_id)
        member.set_editable_role_ids(role_ids)

        if installed_plugin?(:redmine_limited_visibility)
          function_ids = params[:membership][:function_ids]

          entries << JournalDetail.new(
            :property => 'members',
            :prop_key => 'member_roles_and_functions',
            :value    => {
              :name => member.principal.to_s,
              :roles => Role.where(id: role_ids).pluck(:name),
              :functions => Function.where(id: function_ids).pluck(:name)
            }.to_json
          )
        else
          entries << JournalDetail.new(
            :property => 'members',
            :prop_key => 'member_with_roles',
            :value    => { :name => member.principal.to_s, :roles => Role.where(id: role_ids).pluck(:name) }.to_json
          )
        end
      end
    end

    add_journal_entry @project, entries unless entries.empty?
  end

  def journalized_members_upgrade
    if installed_plugin?(:redmine_limited_visibility)
      return if @previous_role_ids == @member.roles.ids && @previous_function_ids == @member.functions.ids
    else
      return if @previous_role_ids == @member.roles.ids
    end

    previous_roles = Role.where(id: @previous_role_ids).pluck(:name)
    new_roles = Role.where(id: @member.roles.ids).pluck(:name)

    if installed_plugin?(:redmine_limited_visibility)
      previous_functions = Function.where(id: @previous_function_ids).pluck(:name)
      new_functions = Function.where(id: @member.functions.ids).pluck(:name)

      add_journal_entry @project, JournalDetail.new(
        :property  => :members,
        :prop_key  => 'member_roles_and_functions',
        :old_value => {
          :name => @member.principal.to_s,
          :roles => previous_roles,
          :functions => previous_functions,
        }.to_json,
        :value     => {
          :name => @member.principal.to_s,
          :roles => new_roles,
          :functions => new_functions,
        }.to_json
      )
    else
      add_journal_entry @project, JournalDetail.new(
        :property  => :members,
        :prop_key  => 'member_with_roles',
        :old_value => { :name => @member.principal.to_s, :roles => previous_roles }.to_json,
        :value     => { :name => @member.principal.to_s, :roles => new_roles }.to_json
      )
    end
  end

  # Called after a member is removed
  def journalized_member_deletion
    # key = (added_or_removed == :removed ? :old_value : :value)
    if installed_plugin?(:redmine_limited_visibility)
      add_journal_entry @project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_roles_and_functions',
        :old_value => {
          :name => @member.principal.to_s,
          :roles => Role.where(id: @previous_role_ids).pluck(:name),
          :functions => Function.where(id: @previous_function_ids).pluck(:name)
        }.to_json
      )
    else
      add_journal_entry @project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_with_roles',
        :old_value => { :name => @member.principal.to_s, :roles => Role.where(id: @previous_role_ids).pluck(:name) }.to_json
      )
    end
  end
end
