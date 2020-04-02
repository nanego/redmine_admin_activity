require_dependency 'settings_controller'

class SettingsController
  before_action :intialize_settings_was, :only => [:edit]
  after_action :track_settings_was_changes, :only => [:edit]

  private

  def intialize_settings_was
    @settings_was = Setting.pluck(:name).map { |name| [name.to_sym, Setting[name]] }
  end

  def track_settings_was_changes
    settings_was = @settings_was.dup
    changes = settings_was.map do |entry|
      name = entry[0]
      old_value = entry[1]
      new_value = Setting[entry[0]]
      [name, [old_value, new_value]]
    end

    changes = changes.reject { |entry| entry[1][0] == entry[1][1] }.to_h

    return unless changes.any?

    journal_entry = JournalSetting.new(
      :user_id => User.current.id,
      :value_changes => changes
    )
    journal_entry.save
  end
end
