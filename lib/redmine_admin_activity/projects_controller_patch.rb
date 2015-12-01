require_dependency 'projects_controller'
require_dependency 'project'

class ProjectsController

  before_filter :init_journal, :only => [:update]
  before_filter :init_modules_journal, :only => [:modules]
  after_filter :update_modules_journal, :only => [:modules]

  def init_journal
    @project.init_journal(User.current)
  end

  # Called after a relation is added
  def init_modules_journal
    init_journal
    # key = (added_or_removed == :removed ? :old_value : :value)
    @project.current_journal.details << JournalDetail.new(
        :property  => 'modules',
        :prop_key  => 'modules',
        :old_value => @project.enabled_module_names.join(',')
    )
  end

  def update_modules_journal
    @project.current_journal.details.first[:value] = @project.enabled_module_names.join(',')
    @project.current_journal.save
  end

end
