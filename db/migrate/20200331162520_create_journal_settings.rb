class CreateJournalSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :journal_settings do |t|
      t.json :value_changes, :null => false
      t.references :user, :foreign_key => true, :null => false, type: :integer
      t.datetime :created_on, :null => false
    end unless ActiveRecord::Base.connection.table_exists? 'journal_settings'
  end
end
