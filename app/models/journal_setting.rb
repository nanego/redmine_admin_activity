class JournalSetting < ActiveRecord::Base
  belongs_to :user, :optional => false
  belongs_to :journalized, :polymorphic => true, :optional => true

  attr_accessor :indice

  validates :value_changes, :presence => true

  def creation?
    journalized_entry_type == "create"
  end

  def deletion?
    journalized_entry_type == "destroy"
  end

  def duplication?
    journalized_entry_type == "copy"
  end
end
