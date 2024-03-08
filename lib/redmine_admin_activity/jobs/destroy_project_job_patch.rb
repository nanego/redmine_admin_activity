module RedmineAdminActivity::Jobs
  module DestroyProjectJobPatch

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods
      def schedule(project, user: User.current)
        projects_to_destroy = project.self_and_descendants
        projects_to_destroy.each do |p|
          changes = p.attributes.to_a.map { |i| [i[0], [i[1], nil]] }.to_h
          JournalSetting.create(
            :user_id => User.current.id,
            :value_changes => changes,
            :journalized => p,
            :journalized_entry_type => "destroy",
            )
        end

        super
      end
    end

  end
end

if Redmine::VERSION::MAJOR >= 5
  class DestroyProjectJob < ApplicationJob
    prepend RedmineAdminActivity::Jobs::DestroyProjectJobPatch
  end
end
