require_dependency 'members_controller'

class MembersController

  before_action :journalized_member_deletion, :only => [:destroy]
  after_action :journalized_members_creation, :only => [:create]

  # Called after a member is removed
  def journalized_member_deletion
    project = @member.project
    project.init_journal(User.current)
    # key = (added_or_removed == :removed ? :old_value : :value)
    project.current_journal.details << JournalDetail.new(
      :property  => 'attr',
      :prop_key  => 'member',
      :old_value => @member.principal
    )
    project.current_journal.save
  end

  def journalized_members_creation

    members = []
    if params[:membership]
      user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids])
      user_ids << nil if user_ids.empty?
      user_ids.each do |user_id|
        member = Member.new(:project => @project, :user_id => user_id)
        member.set_editable_role_ids(params[:membership][:role_ids])
        members << member
      end
    end

    @project.init_journal(User.current)
    @project.current_journal.details << JournalDetail.new(
      :property  => 'attr',
      :prop_key  => 'members',
      :value => members.map{|m|m.principal.to_s}.join(', ')
    )
    @project.current_journal.save
  end

end
