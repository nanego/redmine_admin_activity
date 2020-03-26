require_dependency 'projects_controller'

class ProjectsController
  before_action :init_journal, :only => [:update]
  after_action :update_journal, :only => [:update]

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
end
