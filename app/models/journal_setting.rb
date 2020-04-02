class JournalSetting < ActiveRecord::Base
  # serialize :value_changes, JSON

  belongs_to :user

  attr_accessor :indice
end
