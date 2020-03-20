require_dependency 'members_controller'

class MembersController
  include RedmineAdminActivity::ControllerHelpers

  before_action :store_role_ids, :only => [:update]
  after_action :journalized_members_creation, :only => [:create]
  after_action :journalized_members_upgrade, :only => [:update]
  after_action :journalized_member_deletion, :only => [:destroy]

  private

  def store_role_ids
    member = Member.find(params[:id])
    @previous_role_ids = member.role_ids
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

        entries << JournalDetail.new(
          :property => 'members',
          :prop_key => 'members',
          :value    => { :name => member.principal.to_s, :roles => Role.where(id: role_ids).pluck(:name) }.to_json
        )
      end
    end

    add_journal_entry @project, entries unless entries.empty?
  end

  def journalized_members_upgrade
    return if @previous_role_ids == @member.roles.ids

    previous_roles = Role.where(id: @previous_role_ids - @member.roles.ids).pluck(:name)
    new_roles = Role.where(id: @member.roles.ids - @previous_role_ids).pluck(:name)

    add_journal_entry @project, JournalDetail.new(
      :property  => :members,
      :prop_key  => :members,
      :old_value => { :name => @member.principal.to_s, :roles => previous_roles }.to_json,
      :value     => { :name => @member.principal.to_s, :roles => new_roles }.to_json
    )
  end

  # Called after a member is removed
  def journalized_member_deletion
    # key = (added_or_removed == :removed ? :old_value : :value)
    add_journal_entry @project, JournalDetail.new(
      :property  => 'members',
      :prop_key  => 'members',
      :old_value => { :name => @member.principal.to_s, :roles => Role.where(id: @member.roles.ids).pluck(:name) }.to_json
    )
  end
end
