require_dependency 'trackers_controller'

class TrackersController
  before_action :store_project_ids, :only => [:update]
  after_action :journalized_trackers_creation, :only => [:create]
  after_action :journalized_trackers_upgrade, :only => [:update]
  before_action :journalized_trackers_deletion_preparation, :only => [:destroy]
  after_action :journalized_trackers_deletion, :only => [:destroy]

  private

  def store_project_ids
    # binding.irb
    tracker = Tracker.find(params[:id])
    @previous_project_ids = tracker.project_ids
  end

  def journalized_trackers_creation
    # TODO: check projects
    return unless @tracker.persisted?

    @tracker.projects.each do |project|
      add_journal_entry project, JournalDetail.new(
        :property  => :trackers,
        :prop_key  => :trackers,
        :value => @tracker.name
      )
    end
  end

  def journalized_trackers_upgrade
    # binding.irb
    return if @previous_project_ids == @tracker.project_ids

    changed_project_ids = array_difference(@previous_project_ids, @tracker.project_ids)

    Project.where(id: changed_project_ids).find_each do |project|
      journal_detail = JournalDetail.new(
        :property  => :trackers,
        :prop_key  => :trackers
      )

      if @previous_project_ids.include?(project.id) && !@tracker.project_ids.include?(project.id)
        journal_detail.old_value = @tracker.name
      elsif !@previous_project_ids.include?(project.id) && @tracker.project_ids.include?(project.id)
        journal_detail.value = @tracker.name
      end

      add_journal_entry project, journal_detail
    end
  end

  def journalized_trackers_deletion_preparation
    @jouarnals_projects = []

    tracker = Tracker.find(params[:id])
    tracker.projects.each do |project|
      project.init_journal(User.current)
      project.current_journal.details << JournalDetail.new(
        :property  => :trackers,
        :prop_key  => :trackers,
        :old_value => tracker.name
      )
      @jouarnals_projects << project
    end
  end

  def journalized_trackers_deletion
    @jouarnals_projects.each { |project| project.current_journal.save }
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
