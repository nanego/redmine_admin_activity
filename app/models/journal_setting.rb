class JournalSetting < ActiveRecord::Base
  belongs_to :user, :optional => false
  belongs_to :journalized, :polymorphic => true, :optional => true

  attr_accessor :indice
  scope :by_type, ->(type) { where(journalized_type: type) }

  scope :search_scope, (lambda do |q|
    q = q.to_s
    if q.present?

      query_project = find_by_sql "SELECT * FROM journal_settings JOIN #{Project.table_name} ON journalized_id = #{Project.table_name}.id and LOWER(#{Project.table_name}.name) LIKE LOWER('%#{q}%') "
      query_organization = find_by_sql "SELECT * FROM journal_settings JOIN #{Organization.table_name} ON journalized_id = #{Organization.table_name}.id and LOWER(#{Organization.table_name}.name) LIKE LOWER('%#{q}%') "
      query_customfield = find_by_sql "SELECT * FROM journal_settings JOIN #{CustomField.table_name} ON journalized_id = #{CustomField.table_name}.id and LOWER(#{CustomField.table_name}.name) LIKE LOWER('%#{q}%') "
      query_principal = find_by_sql "SELECT * FROM journal_settings JOIN #{Principal.table_name} ON journalized_id = #{Principal.table_name}.id  and ((LOWER(#{Principal.table_name}.lastname) || ' ' || LOWER(#{Principal.table_name}.firstname)) LIKE LOWER('%#{q}%')
               OR (LOWER(#{Principal.table_name}.firstname) || ' ' || LOWER(#{Principal.table_name}.lastname)) LIKE LOWER('%#{q}%'))"
     
      # union of 4 query
      array_all = by_type('Project').where(journalized_id: query_project.map(&:journalized_id)) + 
        by_type('Organization').where(journalized_id: query_organization.map(&:journalized_id)) + 
        by_type('IssueCustomField').where(journalized_id: query_customfield.map(&:journalized_id))+
        by_type('Principal').where(journalized_id: query_principal.map(&:journalized_id))

      JournalSetting.where(id: array_all.map(&:id))
 
    end
  end)

  validates :value_changes, :presence => true

  def creation?
    journalized_entry_type == "create"
  end

  def deletion?
    journalized_entry_type == "destroy"
  end

  def duplication?
    journalized_entry_type == "copy"
  end

  def activation? 
    journalized_entry_type == "active"
  end

  def closing?    
    journalized_entry_type == "close"
  end

  def archivation?    
    journalized_entry_type == "archive"
  end

  def reopening?    
    journalized_entry_type == "reopen"
  end

  def locking?
    journalized_entry_type == "lock"
  end

  def unlocking?
    journalized_entry_type == "unlock"
  end
  
  def updating?
    journalized_entry_type == "update"
  end

end
