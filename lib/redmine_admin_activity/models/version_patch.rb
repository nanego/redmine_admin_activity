require_dependency 'version'

module RedmineAdminActivity::Models
  module VersionPatch
    def log_version_creation
      project.add_journal_entry(property: 'versions', value: name)
    end

    def log_version_update
      if name != @prev_version.name
        project.add_journal_entry(property: 'versions', value: name, old_value: @prev_version.name)
      end
    end

    def log_version_deletion
      project.add_journal_entry(property: 'versions', value: nil, old_value: name)
    end

    def save_previous_version
      @prev_version = Version.find(self.id)
    end
  end
end

class Version < ApplicationRecord
  prepend RedmineAdminActivity::Models::VersionPatch

  before_update :save_previous_version

  after_create :log_version_creation
  after_update :log_version_update
  after_destroy :log_version_deletion
end

