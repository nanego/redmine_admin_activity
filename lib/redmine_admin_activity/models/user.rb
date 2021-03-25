require_dependency 'user'

class User < Principal

	has_many :JournalSetting, :dependent => :nullify

end