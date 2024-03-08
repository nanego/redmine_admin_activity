require_dependency 'organizations_controller' if Redmine::VERSION::MAJOR < 5

module RedmineAdminActivity::Controllers
  module OrganizationsControllerPatch
    extend ActiveSupport::Concern

    def journalized_organizations_creation
      return unless @organization.present? && @organization.persisted?
      @organization.journalize_creation(User.current)
    end

    def journalized_organizations_deletion
      return unless @organization.destroyed?

      @deleted_organizations.each do |org|
        changes = org.attributes.to_a.map { |i| [i[0], [i[1], nil]] }.to_h

        JournalSetting.create(
          :user_id => User.current.id,
          :value_changes => changes,
          :journalized => org,
          :journalized_entry_type => "destroy",
        )
      end

    end

    def memorize_deleted_organizations
      @deleted_organizations = @organization.self_and_descendants.to_a
    end

    def memorize_attributes_organizations
      @old_attributes = @organization.attributes
    end

    def journalized_organizations_update
      # Build hash of previous_changes manually, After a long search, I couldn't know why the previous changes are empty when changing the parent.
      @previous_changes = {}
      @new_attributes = @organization.attributes
      @new_attributes.each do |key, val|
        @previous_changes[key] =
          [@old_attributes[key], val] if @organization.journalized_attribute_names.include?(key) && @old_attributes[key] != val
      end

      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => @previous_changes,
        :journalized => @organization,
        :journalized_entry_type => "update",
      )
    end
  end
end

class OrganizationsController < ApplicationController

  prepend RedmineAdminActivity::Controllers::OrganizationsControllerPatch

  after_action :journalized_organizations_creation, :only => [:create]
  after_action :journalized_organizations_deletion, :only => [:destroy]
  before_action :memorize_deleted_organizations, :only => [:destroy]
  before_action :memorize_attributes_organizations, :only => [:update]
  after_action :journalized_organizations_update, :only => [:update]

end
