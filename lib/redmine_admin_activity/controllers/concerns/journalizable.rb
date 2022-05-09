module RedmineAdminActivity::Journalizable

  def installed_plugin?(name)
    Redmine::Plugin.installed?(name)
  end

  def limited_visibility_plugin_installed?
    installed_plugin?(:redmine_limited_visibility)
  end

  # Store a [JournalDetail] or an array of [JournalDetail]s in a new
  # journal entry (project , user) for current User.
  def add_journal_entry(journalized, journal_details)
    return unless (journalized.respond_to?(:init_journal) && journalized.respond_to?(:current_journal))

    journalized.init_journal(User.current)

    journal_details = [journal_details] unless journal_details.is_a?(Array)
    journal_details.each do |journal_detail|
      journalized.current_journal.details << journal_detail
    end

    journalized.current_journal.save
  end

  def add_member_journal_entry(project:, value: nil, old_value: nil)
    prop_key = limited_visibility_plugin_installed? ? 'member_roles_and_functions' : 'member_with_roles'
    value = value.to_json if value
    old_value = old_value.to_json if old_value
    add_journal_entry project, JournalDetail.new(
        property: 'members',
        prop_key: prop_key,
        value: value,
        old_value: old_value)
  end

  def add_journal_entry_for_user(user:, property:, prop_key:, value: nil, old_value: nil)
    add_journal_entry user, JournalDetail.new(
        property: property,
        prop_key: prop_key,
        value: value,
        old_value: old_value)
  end

  def add_member_creation_to_journal(member, role_ids, function_ids = nil)
    add_member_journal_entry(project: member.project, value: value_hash(member, role_ids, function_ids))
    add_journal_entry_for_user(user: member.user, property: 'associations', prop_key: 'projects', value: member.project.id)
  end

  def add_member_edition_to_journal(member, previous_role_ids, role_ids, previous_function_ids = nil, function_ids = nil)
    value = value_hash(member, role_ids, function_ids)
    old_value = value_hash(member, previous_role_ids, previous_function_ids)
    add_member_journal_entry(project: member.project, value: value, old_value: old_value)
  end

  def add_member_deletion_to_journal(member, previous_role_ids, previous_function_ids = nil)
    add_member_journal_entry(project: member.project, old_value: value_hash(member, previous_role_ids, previous_function_ids))
    add_journal_entry_for_user(user: member.user, property: 'associations', prop_key: 'projects', old_value: member.project.id)
  end

  def value_hash(member, role_ids, function_ids)
    value = {name: member.principal.to_s, roles: Role.where(id: role_ids).pluck(:name)}
    value.merge!({functions: Function.where(id: function_ids).pluck(:name)}) if limited_visibility_plugin_installed?
    value
  end

  def get_previous_has_and_belongs_to_many(obj)
    previous_has_and_belongs_to_many = {}
    obj.class.reflect_on_all_associations(:has_and_belongs_to_many).each do |reflect|
      reflect_ids = obj.send reflect.name
      previous_has_and_belongs_to_many[reflect.name ] = [reflect_ids.map(&:id)]
    end
    previous_has_and_belongs_to_many
  end

  def add_has_and_belongs_to_many_to_previous_changes(obj, changes)
    obj.class.reflect_on_all_associations(:has_and_belongs_to_many).each do |reflect|
      reflect_ids = obj.send reflect.name
      changes[reflect.name] = [nil, reflect_ids.map(&:id)] if reflect_ids.count > 0
    end
    changes
  end

  def update_has_and_belongs_to_many_in_previous_changes(obj, changes, previous_h_a_b_to_m)
    obj.class.reflect_on_all_associations(:has_and_belongs_to_many).each do |reflect|
      reflect_ids = obj.send reflect.name
      # Don't save if the relation m_to_m not changed
      changes[reflect.name] = [previous_h_a_b_to_m[reflect.name].first, reflect_ids.map(&:id)] unless previous_h_a_b_to_m[reflect.name].first.sort == reflect_ids.map(&:id).sort
    end
    changes
  end

  # We can use this function for the relation has_many (cas add, remove), if we want in the future.
  def get_has_many_ids_changes(obj, previous_h_m_ids)
    changes = {}
    # reload the object for the deleting case
    obj.reload
    obj.class.reflect_on_all_associations(:has_many).each do |reflect|
      reflect_ids = obj.send reflect.name
      # Don't save if the relation m_to_m not changed
      changes[reflect.name] = [previous_h_m_ids, reflect_ids.map(&:id)] unless previous_h_m_ids.sort == reflect_ids.map(&:id).sort
    end
    changes
  end

  # This function for Custom fields / enumerations(active, inactive)
  def get_custom_field_enumerations_changes(obj, previous_h_m_ids)
    changes = {}

    reflect = obj.class.reflect_on_all_associations(:has_many).select{ |ref| ref.name == :enumerations }
    previous_enumerations = obj.send reflect[0].name
    previous_enumerations_ids = previous_enumerations.where(active: true).map(&:id).sort
    # reload the object for the deleting case
    obj.reload

    reflect = obj.class.reflect_on_all_associations(:has_many).select{ |ref| ref.name == :enumerations }
    new_enumerations = obj.send reflect[0].name
    new_enumerations_ids = new_enumerations.where(active: true).map(&:id).sort

    # Don't save if the relation m_to_m not changed case adding / deleting of active enumerations)
    if previous_h_m_ids.sort != new_enumerations_ids
      changes[reflect[0].name] = [previous_h_m_ids, new_enumerations.select { |i| i.active }.map(&:id)]
    # (case of activation/ inactivation don't save if the activation m_to_m not changed) or (deleting of inactive enumerations)
    elsif new_enumerations.map(&:active) != previous_enumerations.map(&:active) && previous_enumerations_ids != new_enumerations_ids
      changes[reflect[0].name] = [previous_enumerations_ids , new_enumerations_ids]
    end
    changes
  end
end
