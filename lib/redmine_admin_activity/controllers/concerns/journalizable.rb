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

end
