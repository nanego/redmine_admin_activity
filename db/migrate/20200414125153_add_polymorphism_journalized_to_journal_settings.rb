class AddPolymorphismJournalizedToJournalSettings < ActiveRecord::Migration[5.2]
  def change
    add_reference :journal_settings, :journalized, :null => true, :index => true, :polymorphic => true
  end
end
