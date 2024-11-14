class JournalSetting < ApplicationRecord

  belongs_to :user, :optional => false
  belongs_to :journalized, :polymorphic => true, :optional => true

  attr_accessor :indice

  scope :search_scope, ->(q) do
    q = q.to_s.strip
    if q.present?

      projects_journals_ids = JournalSetting.joins("LEFT JOIN #{Project.table_name} ON journalized_id = #{Project.table_name}.id AND journalized_type = '#{Project.name}'")
                                            .where("LOWER(#{Project.table_name}.name) LIKE LOWER(?)", "%#{q}%")
                                            .pluck(:id)

      custom_fields_journals_ids = JournalSetting.joins("LEFT JOIN #{CustomField.table_name} ON journalized_id = #{CustomField.table_name}.id AND journalized_type LIKE '%CustomField'")
                                                 .where("LOWER(#{CustomField.table_name}.name) LIKE LOWER(?)", "%#{q}%")
                                                 .pluck(:id)

      users_journals_ids = JournalSetting.joins("LEFT JOIN #{Principal.table_name} ON journalized_id = #{Principal.table_name}.id AND journalized_type = '#{Principal.name}'")
                                         .where("(LOWER(#{Principal.table_name}.lastname) || ' ' || LOWER(#{Principal.table_name}.firstname)) LIKE LOWER(?) OR
                                         (LOWER(#{Principal.table_name}.firstname) || ' ' || LOWER(#{Principal.table_name}.lastname)) LIKE LOWER(?)", "%#{q}%", "%#{q}%")
                                         .pluck(:id)

      journal_ids = projects_journals_ids + custom_fields_journals_ids + users_journals_ids

      if Redmine::Plugin.installed?(:redmine_organizations)
        organizations_journals_ids = JournalSetting.joins("LEFT JOIN #{Organization.table_name} ON journalized_id = #{Organization.table_name}.id AND journalized_type = '#{Organization.name}'")
                                                   .where("LOWER(#{Organization.table_name}.name) LIKE LOWER(?)", "%#{q}%")
                                                   .pluck(:id)
        journal_ids += organizations_journals_ids
      end

      where(id: journal_ids)

    end
  end

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

  def auto_creation?
    journalized_entry_type == "auto_creation"
  end
end
