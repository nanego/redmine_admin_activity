require_dependency 'organization'

class Organization < ActiveRecord::Base

  # Returns the names of attributes that are journalized when updating the organization
  def journalized_attribute_names
    names = Organization.column_names - %w(id lft rgt created_at updated_at name_with_parents identifier)
    names
  end

end