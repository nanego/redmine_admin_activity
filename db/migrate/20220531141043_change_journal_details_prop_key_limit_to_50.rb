class ChangeJournalDetailsPropKeyLimitTo50 < ActiveRecord::Migration[5.2]
  def change
    change_column :journal_details, :prop_key, :string, :limit => 50, :default => "", :null => false
  end
end
