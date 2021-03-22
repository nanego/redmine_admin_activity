class UpdateUserIdInJournalSettings < ActiveRecord::Migration[5.2]
  def change
  	change_column_null(:journal_settings, :user_id, true)
  end
end
