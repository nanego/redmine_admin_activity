require_dependency 'project'

class Project < ActiveRecord::Base

  acts_as_watchable

  has_many :journals, :as => :journalized, :dependent => :destroy, :inverse_of => :journalized

  attr_reader :current_journal

  after_save :create_journal

  def init_journal(user)
    @current_journal ||= Journal.new(:journalized => self, :user => user)
  end

  def add_journal_entry(property:, value:, old_value: nil)
    init_journal(User.current)
    current_journal.details << JournalDetail.new(
        property: property,
        prop_key: property,
        value: value,
        old_value: old_value)
    current_journal.save
  end

  # Returns the current journal or nil if it's not initialized
  def current_journal
    @current_journal
  end

  # Returns the names of attributes that are journalized when updating the project
  def journalized_attribute_names
    names = Project.column_names - %w(id root_id lft rgt lock_version created_on updated_on closed_on)
    names
  end

  # Saves the changes in a Journal
  # Called after_save
  def create_journal
    if current_journal
      current_journal.save
    end
  end

  def self.representative_columns
    return ["name"]
  end

  def self.representative_link_path(obj)
    Rails.application.routes.url_helpers.project_url(obj, only_path: true)
  end

end
