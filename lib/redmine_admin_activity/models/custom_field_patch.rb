require_dependency 'custom_field'

module RedmineAdminActivity::Models::CustomFieldPatch
  # Returns the names of attributes that are journalized when updating the custom_field
  def journalized_attribute_names
    names = %w(type name field_format visible is_required description)
    names
  end

  def to_s
    name
  end
end

class CustomField
  prepend RedmineAdminActivity::Models::CustomFieldPatch

  def self.representative_columns
    return ["name"]
  end

  def self.representative_link_path(obj)
    Rails.application.routes.url_helpers.edit_custom_field_url(obj, only_path: true)
  end
end
