require_dependency 'custom_fields_section'

class CustomFieldsSection < ActiveRecord::Base
  def to_s
    name
  end
end