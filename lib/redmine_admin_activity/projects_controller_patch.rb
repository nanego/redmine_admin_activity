require_dependency 'projects_controller'

class ProjectsController
  before_action :init_journal, :only => [:update]
  after_action :update_journal, :only => [:update]
  after_action :journalized_projects_duplication, :only => [:copy]
  after_action :journalized_projects_creation, :only => [:create]
  after_action :journalized_projects_deletion, :only => [:destroy]

  def init_journal
    @project.init_journal(User.current)
    @previous_enabled_module_names = @project.enabled_module_names
    @previous_enabled_tracker_ids = @project.tracker_ids
    @previous_enabled_issue_custom_field_ids = @project.issue_custom_field_ids
  end

  def update_journal
    if @previous_enabled_tracker_ids != @project.tracker_ids
      previous_tracker_names = Tracker.where(:id => @previous_enabled_tracker_ids.map(&:to_i)).sorted.pluck(:name)

      @project.current_journal.details << JournalDetail.new(
        :property => 'trackers',
        :prop_key => 'trackers',
        :value => @project.trackers.map(&:name).join(','),
        :old_value => previous_tracker_names.join(',')
      )
    end

    if @previous_enabled_issue_custom_field_ids != @project.issue_custom_field_ids
      previous_custom_field_names = CustomField.where(:id => @previous_enabled_issue_custom_field_ids.map(&:to_i)).sorted.pluck(:name)

      @project.current_journal.details << JournalDetail.new(
        :property => 'custom_fields',
        :prop_key => 'custom_fields',
        :value => @project.issue_custom_fields.map(&:name).join(','),
        :old_value => previous_custom_field_names.join(',')
      )
    end

    if @previous_enabled_module_names != @project.enabled_module_names
      @project.current_journal.details << JournalDetail.new(
        :property => 'modules',
        :prop_key => 'modules',
        :value => @project.enabled_module_names.join(','),
        :old_value => @previous_enabled_module_names.join(',')
      )
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
end
