require_dependency 'member'

module RedmineAdminActivity::Models::MemberPatch
  def save_project_journal
    if @project_journal
      @project_journal.save
    end
  end

  def update_project_journal
    puts "\n\n001 - JOURNALIZED\n\n"

    @project_journal = self.project.init_journal(nil)
    @project_journal.details << JournalDetail.new(
      :property  => 'members',
      :prop_key  => 'added',
      :value => self.principal
    )
  end
end

class Member < ApplicationRecord
  prepend RedmineAdminActivity::Models::MemberPatch

  attr_reader :project_journal

  # after_create :update_project_journal
  # after_save :save_project_journal
end
