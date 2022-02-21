require_dependency 'organizations_controller'

class OrganizationsController < ApplicationController

  after_action :journalized_organizations_creation, :only => [:create]
  after_action :journalized_organizations_deletion, :only => [:destroy]
  before_action :self_and_descendants, :only => [:destroy]

  private

  def journalized_organizations_creation
    return unless @organization.present? && @organization.persisted?

    # build hash of previous_changes manually, because of in OrganizationsController(new), there is Organization.managed_by
    changes = @organization.attributes.to_a.map { |i| [i[0], [nil, i[1]]] }.to_h

    JournalSetting.create(
      :user_id => User.current.id,
      :value_changes => changes,
      :journalized => @organization,
      :journalized_entry_type => "create",
    )

  end

  def journalized_organizations_deletion
    return unless @organization.destroyed?

    @self_and_descendants.each do |org|
      changes = org.attributes.to_a.map { |i| [i[0], [i[1], nil]] }.to_h

      JournalSetting.create(
        :user_id => User.current.id,
        :value_changes => changes,
        :journalized => org,
        :journalized_entry_type => "destroy",
      )
    end

  end

  def self_and_descendants
    @self_and_descendants = Array.new
    @self_and_descendants.push(@organization)

    @organization.descendants.each do |child|
      @self_and_descendants.push(child)
    end

  end
end