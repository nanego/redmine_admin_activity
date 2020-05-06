require_dependency 'project'

class Project < ActiveRecord::Base

  acts_as_watchable

  has_many :journals, :as => :journalized, :dependent => :destroy, :inverse_of => :journalized

  attr_reader :current_journal

  after_save :create_journal

  def init_journal(user)
    @current_journal ||= Journal.new(:journalized => self, :user => user)
  end

  # Returns the current journal or nil if it's not initialized
  def current_journal
    @current_journal
  end

  # Returns the names of attributes that are journalized when updating the issue
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

end
