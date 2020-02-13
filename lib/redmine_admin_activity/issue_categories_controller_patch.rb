require_dependency 'issue_categories_controller'

class IssueCategoriesController
  after_action :journalized_issue_categories_creation, :only => [:create]
  after_action :journalized_issue_categories_deletion, :only => [:destroy]

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

  def journalized_issue_categories_deletion
    @project.init_journal(User.current)

    @project.current_journal.details << JournalDetail.new(
      :property  => 'issue_category',
      :prop_key  => 'issue_category',
      :old_value => @category.name
    )
    @project.current_journal.save
  end
end
