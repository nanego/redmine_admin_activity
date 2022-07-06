require_dependency 'issue_template'

class IssueTemplate < ActiveRecord::Base
  has_many :template_projects, through: :issue_template_projects, source: :project, before_remove: :journalized_deactivation_template, after_add: :journalized_activation_template

  def journalized_activation_template(project)
    if project.present?
        project.init_journal(User.current)
        project.current_journal.details << JournalDetail.new(
            :property => 'templates',
            :prop_key => 'enabled_template',
            :value => self.template_title,
            :old_value => nil
        )
        project.current_journal.save
    end
  end

  def journalized_deactivation_template(project)
    if project.present?
        project.init_journal(User.current)
        project.current_journal.details << JournalDetail.new(
            :property => 'templates',
            :prop_key => 'enabled_template',
            :value => nil,
            :old_value => self.template_title
        )
        project.current_journal.save
    end
  end
end