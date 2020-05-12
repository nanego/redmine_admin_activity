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
    @deletable_members = to_be_deleted_members.select{|m| (m.roles & User.current.managed_roles(@project)) == m.roles}

    @updated_members = @previous_current_users.map{|u| Member.includes(:roles).find_by(user: u, project: @project)}
      .reject{|m| @deletable_members.include?(m)}
  end

  def journalized_memberships_edition
    @new_users.each do |user|
      member = Member.where(user: user, project: @project).first_or_initialize

      add_member_creation_to_journal(@project, member, @requested_roles.ids, previous_function_ids = nil)
    end

    @updated_members.each do |member|
      previous_role_ids = member.roles.ids
      member.reload
      role_ids = Member.includes(:roles).find_by(user: member.user, project: @project).roles.ids

      next if previous_role_ids == role_ids

      add_member_edition_to_journal(@project, member, previous_role_ids, role_ids, previous_function_ids = nil, function_ids = nil)
    end

    @deletable_members.each do |member|
       add_member_deletion_to_journal(@project, member, member.role_ids, previous_function_ids = nil)
    end
  end

  def add_member_creation_to_journal(project, member, role_ids, function_ids = nil)
    if function_ids.nil?
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_roles_and_functions',
        :value => {
          :name => member.principal.to_s,
          :roles => Role.where(id: role_ids).pluck(:name),
          # :functions => .pluck(:name)
        }.to_json
      )
    else
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_with_roles',
        :value => { :name => member.principal.to_s, :roles => Role.where(id: role_ids).pluck(:name) }.to_json
      )
    end
  end

  def add_member_edition_to_journal(project, member, previous_role_ids, role_ids, previous_function_ids = nil, function_ids = nil)
    if previous_function_ids.nil?
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_roles_and_functions',
        :value => {
          :name => member.principal.to_s,
          :roles => Role.where(id: role_ids).pluck(:name),
          # :functions => .pluck(:name)
        }.to_json,
        :old_value => {
          :name => member.principal.to_s,
          :roles => Role.where(id: previous_role_ids).pluck(:name),
          # :functions => .pluck(:name)
        }.to_json
      )
    else
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_with_roles',
        :value => { :name => member.principal.to_s, :roles => Role.where(id: role_ids).pluck(:name) }.to_json,
        :old_value => { :name => member.principal.to_s, :roles => Role.where(id: previous_role_ids).pluck(:name) }.to_json
      )
    end
  end

  def add_member_deletion_to_journal(project, member, previous_role_ids, previous_function_ids = nil)
    if previous_function_ids.nil?
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_roles_and_functions',
        :old_value => {
          :name => member.principal.to_s,
          :roles => Role.where(id: previous_role_ids).pluck(:name),
          # :functions => .pluck(:name)
        }.to_json
      )
    else
      add_journal_entry project, JournalDetail.new(
        :property  => 'members',
        :prop_key  => 'member_with_roles',
        :old_value => { :name => member.principal.to_s, :roles => Role.where(id: previous_role_ids).pluck(:name) }.to_json
      )
    end
  end
end
