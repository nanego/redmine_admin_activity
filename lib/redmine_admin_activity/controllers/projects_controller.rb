require_dependency 'projects_controller'

class ProjectsController

  helper :journal_settings
  include JournalSettingsHelper

  before_action :init_journal, :only => [:update]
  after_action :update_journal, :only => [:update]
  after_action :journalized_projects_duplication, :only => [:copy]
  after_action :journalized_projects_creation, :only => [:create]
  after_action :journalized_projects_deletion, :only => [:destroy]
  append_before_action :self_and_descendants_or_ancestors, :only => [:close, :archive, :unarchive, :reopen, :destroy]
  after_action :journalized_projects_activation, :only => [:unarchive]
  after_action :journalized_projects_closing, :only => [:close]
  after_action :journalized_projects_archivation, :only => [:archive]
  after_action :journalized_projects_reopen, :only => [:reopen]
  append_before_action :get_projects_journals_for_pagination, :only => [:settings]

  def init_journal
    find_project unless @project
    @project.init_journal(User.current)
    @previous_enabled_module_names = @project.enabled_module_names
    @previous_enabled_tracker_ids = @project.tracker_ids
    @previous_enabled_issue_custom_field_ids = @project.issue_custom_field_ids
    @previous_enabled_template_ids = @project.issue_template_ids if Redmine::Plugin.installed?(:redmine_templates)
  end

  def add_journal_entry(property:, prop_key: nil, value: nil, old_value: nil)
    prop_key = property if prop_key.nil?
    @project.current_journal.details << JournalDetail.new(
      :property => property,
      :prop_key => prop_key,
      :value => value,
      :old_value => old_value
    )
  end

  def update_journal
    @project.init_journal(User.current)

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

    if Redmine::Plugin.installed?(:redmine_templates) && (@previous_enabled_template_ids != @project.issue_template_ids)
      previous_issue_templates_titles = IssueTemplate.where(:id => @previous_enabled_template_ids.map(&:to_i)).pluck(:template_title)
      activated_templates_titles = @project.issue_templates.map(&:template_title) - previous_issue_templates_titles
      deactivated_templates_titles = previous_issue_templates_titles - @project.issue_templates.map(&:template_title)
      activated_templates_titles.each do |temp_title|
        add_journal_entry(property: 'templates',
                          prop_key: 'enabled_template',
                          value: temp_title,
                          old_value: nil)
      end
      deactivated_templates_titles.each do |temp_title|
        add_journal_entry(property: 'templates',
                          prop_key: 'enabled_template',
                          value: nil,
                          old_value: temp_title)
      end
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

    @self_and_descendants_or_ancestors.each do |project|
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
    @self_and_descendants_or_ancestors = case action_name
                                         when "close"
                                           @project.self_and_descendants.status(Project::STATUS_ACTIVE).to_a
                                         when "reopen"
                                           @project.self_and_descendants.status(Project::STATUS_CLOSED).to_a
                                         when "unarchive"
                                           @project.self_and_ancestors.status(Project::STATUS_ARCHIVED).to_a
                                         when "archive", "destroy"
                                           @project.self_and_descendants.to_a
                                         end
  end

  def get_projects_journals_for_pagination
    find_project unless @project
    @scope = get_journal_for_history(@project.journals)
    @journal_count = @scope.count
    @journal_pages = Paginator.new @journal_count, per_page_option, params['page']
    @journals = @scope.limit(@journal_pages.per_page).offset(@journal_pages.offset).to_a
    @journals = add_index_to_journal_for_history(@journals)
  end

end
