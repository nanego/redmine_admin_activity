require_dependency 'settings_controller'

class SettingsController
  before_action :intialize_settings_was, :only => [:edit]
  after_action :track_settings_was_changes, :only => [:edit]
  before_action :get_settings_journals_for_pagination, :only => [:index]

  helper :journal_settings
  include JournalSettingsHelper

  private

  def intialize_settings_was
    @settings_was = Setting.pluck(:name)
                        .select { |name| Setting.find_by_name(name).valid? }
                        .map { |name| [name.to_sym, Setting[name]] }
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

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes
    )
  end

  def get_settings_journals_for_pagination
    @scope = JournalSetting.includes(:user).
    reorder(created_on: :desc).
    references(:user)
    @journal_count = @scope.count
    @journal_pages = Paginator.new @journal_count, per_page_option, params['page'] 
    @journals = @scope.limit(@journal_pages.per_page).offset(@journal_pages.offset).to_a   
    @journals = add_index_to_journal_for_history(@journals)
  end

end
