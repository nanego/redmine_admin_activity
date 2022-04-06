require_dependency 'custom_field'

class CustomField < ActiveRecord::Base
	# Returns the names of attributes that are journalized when updating the custom_field
	# TODO à discuter

  def journalized_attribute_names
    names = %w(type name field_format visible)
    names
  end
end