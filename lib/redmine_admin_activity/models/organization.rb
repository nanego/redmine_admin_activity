require_dependency 'organization'

class Organization < ActiveRecord::Base

  # Returns the names of attributes that are journalized when updating the organization
  def journalized_attribute_names
    names = Organization.column_names - %w(id lft rgt created_at updated_at name_with_parents identifier)
    names
  end

  def self.representative_columns
    return ["name_with_parents"]
  end

  def self.representative_link_path(obj)
    Rails.application.routes.url_helpers.organization_url(obj, only_path: true)
  end
end