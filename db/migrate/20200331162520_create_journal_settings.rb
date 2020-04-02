class CreateJournalSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :journal_settings do |t|
      t.json :value_changes
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
