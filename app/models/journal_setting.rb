class JournalSetting < ActiveRecord::Base
  belongs_to :user, :optional => false
  belongs_to :journalized, :polymorphic => true, :optional => true

  attr_accessor :indice

  validates :value_changes, :presence => true

  def creation?
    value_changes["id"][0].nil? && !value_changes["id"][1].nil?
  end

  def deletion?
    !value_changes["id"][0].nil? && value_changes["id"][1].nil?
  end
end
