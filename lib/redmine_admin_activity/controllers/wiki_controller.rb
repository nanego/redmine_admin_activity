require_dependency 'wiki_controller'

class WikiController
  include RedmineAdminActivity::Journalizable

  before_action :keep_self_and_descendants, :only => [:destroy]
  after_action :journalize_wiki_page_deletion, :only => [:destroy]

  def keep_self_and_descendants
    @kept_self_and_descendants = [@page] # case of leaf page, or page without children, or page with children and params[:todo] = nullify or reassign
    @kept_self_and_descendants += @page.descendants.to_a if params[:todo].present? && params[:todo] == 'destroy'
  end

  def journalize_wiki_page_deletion
    return unless @page.present? && @page.destroyed?

    @kept_self_and_descendants.each do |wiki|
      add_wiki_page_journal_entry(project: wiki.project,
                                  value: nil,
                                  old_value: wiki.title)
    end
  end

end
