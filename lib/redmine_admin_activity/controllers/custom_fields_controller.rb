require_dependency 'custom_fields_controller'

class CustomFieldsController
  include RedmineAdminActivity::Journalizable

  append_before_action :store_project_ids, :only => [:update]
  after_action :custom_fields_creation, :only => [:create]
  after_action :custom_fields_upgrade, :only => [:update]
  before_action :custom_fields_deletion_preparation, :only => [:destroy]
  after_action :custom_fields_deletion, :only => [:destroy]

  private

  def store_project_ids
    @previous_has_and_belongs_to_many = get_previous_has_and_belongs_to_many(@custom_field)
    @previous_project_ids = @custom_field.project_ids if trackable_custom_field?
  end

  def custom_fields_creation
    return unless @custom_field.persisted?

    # Tracing on JournalSetting
    changes = add_has_and_belongs_to_many_to_previous_changes(
              @custom_field,
              @custom_field.previous_changes
             )
    # Pass @custom_field.class.name in order to use the child class,
    # Not using the parent class, to be able to retrieve the correct associations
    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes,
      :journalized_type => @custom_field.class.name,
      :journalized_id => @custom_field.id,
      :journalized_entry_type => "create",
    )

    if trackable_custom_field?
      @custom_field.projects.each do |project|
        add_journal_entry project, JournalDetail.new(
          :property => :custom_fields,
          :prop_key => :custom_fields,
          :value => @custom_field.name
        )
      end
    end
  end

  def custom_fields_upgrade
    # Tracing on JournalSetting
    journalized_changes = @custom_field.previous_changes.select { |key, val| @custom_field.journalized_attribute_names.include?(key) }

    changes = update_has_and_belongs_to_many_in_previous_changes(@custom_field,
                journalized_changes,
                @previous_has_and_belongs_to_many
              )
    # Pass @custom_field.class.name in order to use the child class,
    # Not using the parent class, to be able to retrieve the correct associations
    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes,
      :journalized_type => @custom_field.class.name,
      :journalized_id => @custom_field.id,
      :journalized_entry_type => "update",
    )

    return unless trackable_custom_field? && @previous_project_ids != @custom_field.project_ids

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
    return unless trackable_custom_field?

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
    return unless @custom_field.present? && @custom_field.destroyed?

    # Tracing on JournalSetting
    changes = Array.new
    @custom_field.attributes.to_a.map do |col|
      changes << [col[0], [col[1], nil]] if @custom_field.journalized_attribute_names.include?(col.first)
    end

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes =>  changes.to_h,
      :journalized_type => @custom_field.class.name,
      :journalized_id => @custom_field.id,
      :journalized_entry_type => "destroy",
    )

    return unless trackable_custom_field?

    @journals_projects.each { |project| project.current_journal.save }
  end

  def array_difference(arr1, arr2)
    arr1 - arr2 | arr2 - arr1
  end

  def trackable_custom_field?
    @custom_field.is_a?(IssueCustomField)
  end
end
