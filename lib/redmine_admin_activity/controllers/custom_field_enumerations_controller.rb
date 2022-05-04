require_dependency 'custom_field_enumerations_controller'

class CustomFieldEnumerationsController
  include RedmineAdminActivity::Journalizable

  append_before_action :get_previous_custom_field_enumerations, :only => [:create, :destroy, :update_each]
  after_action :create_custom_field_history, :only => [:create, :destroy, :update_each]

  private

  def get_previous_custom_field_enumerations
  	@previous_custom_field_enumerations_ids = @custom_field.enumerations.select { |i| i.active }.map(&:id)
  end

  def create_custom_field_history

  	changes = get_custom_field_enumerations_changes(@custom_field, @previous_custom_field_enumerations_ids)

  	JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes.except!(:custom_values),
      :journalized_type => @custom_field.class.name,
      :journalized_id => @custom_field.id,
      :journalized_entry_type => "update",
    )

  end
end