class JournalSetting < ActiveRecord::Base
  belongs_to :user, optional: false

  attr_accessor :indice

  validates :value_changes, presence: true
end
