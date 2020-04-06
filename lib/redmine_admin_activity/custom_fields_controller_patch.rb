require_dependency 'custom_fields_controller'

class CustomFieldsController
  append_before_action :store_project_ids, :only => [:update]
  after_action :custom_fields_creation, :only => [:create]
  after_action :custom_fields_upgrade, :only => [:update]
  before_action :custom_fields_deletion_preparation, :only => [:destroy]
  after_action :custom_fields_deletion, :only => [:destroy]

  private

  def store_project_ids
    @previous_project_ids = @custom_field.project_ids if @custom_field.is_a?(IssueCustomField)
  end

  def custom_fields_creation
    return unless @custom_field.persisted? && @custom_field.is_a?(IssueCustomField)

    @custom_field.projects.each do |project|
      add_journal_entry project, JournalDetail.new(
        :property => :custom_fields,
        :prop_key => :custom_fields,
        :value => @custom_field.name
      )
    end
  end

  def custom_fields_upgrade
    return unless @custom_field.is_a?(IssueCustomField) && @previous_project_ids != @custom_field.project_ids

    changed_project_ids = array_difference(@previous_project_ids, @custom_field.project_ids)

    Project.where(id: changed_project_ids).find_each do |project|
      journal_detail = JournalDetail.new(
        :property => :custom_fields,
        :prop_key => :custom_fields
      )

      if @previous_project_ids.include?(project.id) && !@custom_field.project_ids.include?(project.id)
        journal_detail.old_value = @custom_field.name
      elsif !@previous_project_ids.include?(project.id) && @custom_field.project_ids.include?(project.id)
        journal_detail.value = @custom_field.name
      end

      add_journal_entry project, journal_detail
    end
  end

  def custom_fields_deletion_preparation
    return unless @custom_field.is_a?(IssueCustomField)

    @journals_projects = []
    custom_field = CustomField.find(params[:id])
    custom_field.projects.each do |project|
      project.init_journal(User.current)
      project.current_journal.details << JournalDetail.new(
        :property  => :custom_fields,
        :prop_key  => :custom_fields,
        :old_value => custom_field.name
      )
      @journals_projects << project
    end
  end

  def custom_fields_deletion
    return unless @custom_field.is_a?(IssueCustomField)
    @journals_projects.each { |project| project.current_journal.save }
  end

  def add_journal_entry(project, journal_detail)
    project.init_journal(User.current)
    project.current_journal.details << journal_detail
    project.current_journal.save
  end

  def array_difference(arr1, arr2)
    arr1 - arr2 | arr2 - arr1
  end
end
