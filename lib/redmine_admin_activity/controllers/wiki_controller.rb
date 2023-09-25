require_dependency 'wiki_controller'

class WikiController
  include RedmineAdminActivity::Journalizable

  after_action :journalized_wiki_deletion, :only => [:destroy]
  before_action :self_and_descendants, :only => [:destroy]

  def self_and_descendants
    @self_and_descendants = [@page] # case of leaf page, or page without children, or page with children and params[:todo] = nullify or reassign
    @self_and_descendants +=  @page.descendants.to_a if params[:todo].present? && params[:todo] == 'destroy'
  end

  def journalized_wiki_deletion
    return unless @page.present? && @page.destroyed?

    @self_and_descendants.each do |wiki|

      add_wiki_journal_entry(project: wiki.project,
                            value: nil,
                            old_value: wiki.title)
    end
  end

end