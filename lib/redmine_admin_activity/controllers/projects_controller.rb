require_dependency 'projects_controller'

class ProjectsController

  before_action :init_journal, :only => [:update]  
  after_action :update_journal, :only => [:update]
  after_action :journalized_projects_duplication, :only => [:copy]
  after_action :journalized_projects_creation, :only => [:create]
  after_action :journalized_projects_deletion, :only => [:destroy]
  before_action :self_and_descendants_or_ancestors, :only => [:close, :archive, :unarchive, :reopen]
  after_action :journalized_projects_activation, :only => [:unarchive] 
  after_action :journalized_projects_closing, :only => [:close]
  after_action :journalized_projects_archivation, :only => [:archive]
  after_action :journalized_projects_reopen, :only => [:reopen]
  before_action :get_self_and_descendants, :only => [:destroy]

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
    return unless @project_to_destroy.present? && @project_to_destroy.destroyed?

    @self_and_descendants.each do |project|
      changes = project.attributes.to_a.map { |i| [i[0], [i[1], nil]] }.to_h

      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => changes,
        :journalized => project,
        :journalized_entry_type => "destroy",
      )
    end
  end

  def journalized_projects_activation
    return unless @project.present? && @project.persisted?

    new_status = @project.ancestors.any?(&:closed?) ? Project::STATUS_CLOSED : Project::STATUS_ACTIVE
    entry_type = @project.ancestors.any?(&:closed?) ? "close" : "active"    
    @self_and_descendants_or_ancestors.each do |ancestor|
      # build hash of previous_changes manually
      previous_changes = { 
        "status" => [Project::STATUS_ARCHIVED, new_status],
      }

      # Saves the changes in a JournalDetail
      ancestor.add_journal_entry(property: 'status',
                              value: new_status,
                              old_value: Project::STATUS_ARCHIVED)

      # Saves the changes in a JournalSetting 
      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => previous_changes,
        :journalized => ancestor,
        :journalized_entry_type => entry_type,
      )      
    end
  end

  def journalized_projects_closing
    return unless @project.present? && @project.persisted?

    @self_and_descendants_or_ancestors.each do |child|
      # build hash of previous_changes manually      
      previous_changes = { 
        "status" => [Project::STATUS_ACTIVE, Project::STATUS_CLOSED],
      }

      # Saves the changes in a JournalDetail
      child.add_journal_entry(property: 'status',
                              value: Project::STATUS_CLOSED,
                              old_value: Project::STATUS_ACTIVE)

      # Saves the changes in a JournalSetting 
      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => previous_changes,
        :journalized => child,
        :journalized_entry_type => "close",
      )
    end
  end

  def journalized_projects_archivation
    return unless @project.present? && @project.persisted?

    @self_and_descendants_or_ancestors.each do |child|

      if child.status != Project::STATUS_ARCHIVED
        # build hash of previous_changes manually
        previous_changes = { 
          "status" => [child.status, Project::STATUS_ARCHIVED],
        }

        # Saves the changes in a JournalDetail
        child.add_journal_entry(property: 'status',
                                value: Project::STATUS_ARCHIVED,
                                old_value: child.status)

        # Saves the changes in a JournalSetting 
        JournalSetting.create(
          :user_id => User.current.id,
          :value_changes => previous_changes,
          :journalized => child,
          :journalized_entry_type => "archive",
        )
      end  
    end
  end

  def journalized_projects_reopen     
    return unless @project.present? && @project.persisted?

    @self_and_descendants_or_ancestors.each do |child|
      # build hash of previous_changes manually
      previous_changes = { 
        "status" => [Project::STATUS_CLOSED, Project::STATUS_ACTIVE],
      }

      # Saves the changes in a JournalDetail
      child.add_journal_entry(property: 'status',
                              value: Project::STATUS_ACTIVE,
                              old_value: Project::STATUS_CLOSED)

      # Saves the changes in a JournalSetting 
      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => previous_changes,
        :journalized => child,
        :journalized_entry_type => "reopen",
      )
    end
  end

  def self_and_descendants_or_ancestors
    @self_and_descendants_or_ancestors = Array.new
    case action_name
    when "close"
      @project.self_and_descendants.status(Project::STATUS_ACTIVE).each do |child|
        @self_and_descendants_or_ancestors.push(child)
      end
    when "reopen"
      @project.self_and_descendants.status(Project::STATUS_CLOSED).each do |child|
        @self_and_descendants_or_ancestors.push(child)
      end
    when "unarchive"
      @project.self_and_ancestors.status(Project::STATUS_ARCHIVED).each do |ancestor|
        @self_and_descendants_or_ancestors.push(ancestor)
      end
    when "archive"
      @project.self_and_descendants.each do |child|
        @self_and_descendants_or_ancestors.push(child) 
      end
    end
  end

  def get_self_and_descendants
    @self_and_descendants = @project.self_and_descendants.to_a
  end
end
