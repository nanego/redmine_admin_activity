require_dependency 'projects_controller'

class ProjectsController
  include RedmineAdminActivity::Journalizable

  before_action :init_journal, :only => [:update, :close, :unarchive]
  before_action :last_updated_on, :only => [:close, :unarchive, :reopen]
  after_action :update_journal, :only => [:update]
  after_action :journalized_projects_duplication, :only => [:copy]
  after_action :journalized_projects_creation, :only => [:create]
  after_action :journalized_projects_deletion, :only => [:destroy]
  after_action :journalized_projects_activation, :only => [:unarchive]
  after_action :journalized_projects_closing, :only => [:close]
  after_action :journalized_projects_archivation, :only => [:archive]
  after_action :journalized_projects_reopen, :only => [:reopen]

  def init_journal    
    @project.init_journal(User.current)
    @previous_enabled_module_names = @project.enabled_module_names
    @previous_enabled_tracker_ids = @project.tracker_ids
    @previous_enabled_issue_custom_field_ids = @project.issue_custom_field_ids
  end

  def add_journal_entry(property:, value: nil, old_value: nil)
    @project.current_journal.details << JournalDetail.new(
        :property => property,
        :prop_key => property,
        :value => value,
        :old_value => old_value
    )
  end

  def update_journal
    if @previous_enabled_tracker_ids != @project.tracker_ids
      previous_tracker_names = Tracker.where(:id => @previous_enabled_tracker_ids.map(&:to_i)).sorted.pluck(:name)
      add_journal_entry(property: 'trackers',
                        value: @project.trackers.map(&:name).join(','),
                        old_value: previous_tracker_names.join(','))
    end

    if @previous_enabled_issue_custom_field_ids != @project.issue_custom_field_ids
      previous_custom_field_names = CustomField.where(:id => @previous_enabled_issue_custom_field_ids.map(&:to_i)).sorted.pluck(:name)
      add_journal_entry(property: 'custom_fields',
                        value: @project.issue_custom_fields.map(&:name).join(','),
                        old_value: previous_custom_field_names.join(','))
    end

    if @previous_enabled_module_names != @project.enabled_module_names
      add_journal_entry(property: 'modules',
                        value: @project.enabled_module_names.join(','),
                        old_value: @previous_enabled_module_names.join(','))
    end

    @project.current_journal.save if @project.current_journal.details.any?
  end

  def journalized_projects_duplication
    return unless @project.present? && @project.persisted?

    @project.init_journal(User.current)

    @project.current_journal.details << JournalDetail.new(
      :property => 'copy_project',
      :prop_key => 'copy_project',
      :value => "#{@source_project.name} (id: #{@source_project.id})"
    )

    @project.current_journal.save if @project.current_journal.details.any?

    changes = @project.attributes.to_a.map { |i| [i[0], [nil, i[1]]] }.to_h
    changes["source_project"] = @source_project.id
    changes["source_project_name"] = @source_project.name

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes,
      :journalized => @project,
      :journalized_entry_type => "copy",
    )
  end

  def journalized_projects_creation
    return unless @project.present? && @project.persisted?

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => @project.previous_changes,
      :journalized => @project,
      :journalized_entry_type => "create",
    )
  end

  def journalized_projects_deletion
    return unless @project_to_destroy.destroyed?

    changes = @project_to_destroy.attributes.to_a.map { |i| [i[0], [i[1], nil]] }.to_h

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes,
      :journalized => @project_to_destroy,
      :journalized_entry_type => "destroy",
    )
  end  

  def journalized_projects_activation
    # change modification time because the action unarchive use function update_all which does not change the column updated_at
    @project.update_column :updated_on, Time.now

    return unless @project.present? && @project.persisted?

    #build hash of previous_changes manually
    previous_changes = { 
      "status" => [Project::STATUS_ARCHIVED, Project::STATUS_ACTIVE],
      "updated_on" => [@project_last_updatee_on, @project.updated_on] 
    }
    
    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => previous_changes,
      :journalized => @project,
      :journalized_entry_type => "active",
    )
    
  end

  def journalized_projects_closing
    # change modification time because the action close use function update_all which does not change the column updated_at
    @project.update_column :updated_on, Time.now

    return unless @project.present? && @project.persisted?

    #build hash of previous_changes manually
    previous_changes = { 
      "status" => [Project::STATUS_ACTIVE, Project::STATUS_CLOSED],
      "updated_on" => [@project_last_updatee_on, @project.updated_on] 
    }

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => previous_changes,
      :journalized => @project,
      :journalized_entry_type => "close",
    )
  end

  def journalized_projects_archivation
    return unless @project.present? && @project.persisted?

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => @project.previous_changes,
      :journalized => @project,
      :journalized_entry_type => "archive",
    )
  end

  def journalized_projects_reopen
    # change modification time because the action reopen use function update_all which does not change the column updated_at
    @project.update_column :updated_on, Time.now

    return unless @project.present? && @project.persisted?

  end

  def last_updated_on
    @project_last_updatee_on = @project.updated_on
  end

end
