class JournalSetting < ActiveRecord::Base
  belongs_to :user

  attr_accessor :indice
end
