require_dependency 'projects_controller'
require_dependency 'project'

class ProjectsController

  before_action :init_journal, :only => [:update]
  after_action :update_journal, :only => [:update]

  def init_journal
    @project.init_journal(User.current)
    @previous_enabled_module_names = @project.enabled_module_names
  end

  def update_journal
    if @previous_enabled_module_names != @project.enabled_module_names
      @project.current_journal.details << JournalDetail.new(
          :property  => 'modules',
          :prop_key  => 'modules',
          :old_value => @previous_enabled_module_names.join(','),
          :value => @project.enabled_module_names.join(',')
      )
      @project.current_journal.save
    end
  end

end
