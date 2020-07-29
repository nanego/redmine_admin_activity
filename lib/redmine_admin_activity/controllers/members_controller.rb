require_dependency 'members_controller'

class MembersController
  include RedmineAdminActivity::Journalizable

  before_action :store_role_ids, :only => [:update, :destroy]
  after_action :journalized_members_creation, :only => [:create]
  after_action :journalized_members_upgrade, :only => [:update]
  after_action :journalized_member_deletion, :only => [:destroy]

  private

  def store_role_ids
    member = Member.find(params[:id])
    @previous_role_ids = member.role_ids
    @previous_function_ids = member.function_ids if limited_visibility_plugin_installed?
  end

  def journalized_members_creation
    if params[:membership]
      user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids])
      user_ids << nil if user_ids.empty?
      user_ids.each do |user_id|
        role_ids = params[:membership][:role_ids]
        function_ids = params[:membership][:function_ids]
        member = Member.new(:project => @project, :user_id => user_id)
        member.set_editable_role_ids(role_ids)
        add_member_creation_to_journal(member, role_ids, function_ids)
      end
    end
  end

  def journalized_members_upgrade
    if limited_visibility_plugin_installed?
      return if @previous_role_ids == @member.roles.ids && @previous_function_ids == @member.functions.ids
    else
      return if @previous_role_ids == @member.roles.ids
    end
    add_member_edition_to_journal(@member, @previous_role_ids, @member.roles.ids, @previous_function_ids, @member.functions.ids)
  end

  def journalized_member_deletion
    add_member_deletion_to_journal(@member, @previous_role_ids, @previous_function_ids)
  end
end
