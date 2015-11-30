require_dependency 'projects_controller'
require_dependency 'project'

class ProjectsController

  before_filter :init_journal, :only => [:update]

  def init_journal
    @project.init_journal(User.current)
  end

end


