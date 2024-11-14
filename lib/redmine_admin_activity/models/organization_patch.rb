require_dependency 'organization' if Redmine::VERSION::MAJOR < 5

module RedmineAdminActivity::Models::OrganizationPatch
  # Returns the names of attributes that are journalized when updating the organization
  def journalized_attribute_names
    names = Organization.column_names - %w(id lft rgt created_at updated_at name_with_parents identifier)
    names
  end

  def journalize_creation(user)
    return if !persisted?
    changes = self.attributes.to_a.map { |i| [i[0], [nil, i[1]]] }.to_h
    JournalSetting.create(
      :user_id => user.id,
      :value_changes => changes,
      :journalized => self,
      :journalized_entry_type => "create",
      )
  end
end

class Organization < ApplicationRecord
  prepend RedmineAdminActivity::Models::OrganizationPatch

  def self.representative_columns
    return ["name_with_parents"]
  end

  def self.representative_link_path(obj)
    Rails.application.routes.url_helpers.organization_url(obj, only_path: true)
  end
end
