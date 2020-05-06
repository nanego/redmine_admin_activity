require_dependency 'issue_categories_controller'

class IssueCategoriesController
  before_action :init_journal, :only => [:create, :update, :destroy]
  after_action :journalized_issue_categories_creation, :only => [:create]
  after_action :journalized_issue_categories_upgrade, :only => [:update]
  after_action :journalized_issue_categories_deletion, :only => [:destroy]

  private

  def init_journal
    @project.init_journal(User.current)
  end

  def journalized_issue_categories_creation
    return unless @category.persisted?

    add_journal_entry JournalDetail.new(
        :property  => :issue_category,
        :prop_key  => :issue_category,
        :value => @category.name
    )
  end

  def journalized_issue_categories_upgrade
    return unless @category.name_previously_changed?

    add_journal_entry JournalDetail.new(
      :property  => :issue_category,
      :prop_key  => :issue_category,
      :value => @category.name,
      :old_value => @category.name_previous_change[0]
    )
  end

  def journalized_issue_categories_deletion
    add_journal_entry JournalDetail.new(
      :property  => :issue_category,
      :prop_key  => :issue_category,
      :old_value => @category.name
    )
  end

  def add_journal_entry(journal_detail)
    @project.current_journal.details << journal_detail
    @project.current_journal.save
  end
end
