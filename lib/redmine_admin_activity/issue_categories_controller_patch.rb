require_dependency 'issue_categories_controller'
# require_dependency 'issue_category'

class IssueCategoriesController
  # before_action :init_journal, :only => [:update]
  after_action :journalized_issue_categories_creation, :only => [:create]

  def journalized_issue_categories_creation
    return unless @category.persisted?

    @project.init_journal(User.current)
    @project.current_journal.details << JournalDetail.new(
        :property  => 'issue_category',
        :prop_key  => 'issue_category',
        :value => @category.name
    )
    @project.current_journal.save
  end
end
