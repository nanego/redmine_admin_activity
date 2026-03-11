Redmine Admin Activity
======================

This Redmine plugin keeps a log of all admin actions:

- Changes in project settings
- Modules activations
- Members added or removed
- ...

## Requirements:

  * Ruby >= 3.2.0
  * The [redmine_base_deface](https://github.com/jbbarth/redmine_base_deface) plugin is required to display
    the history link in user pages (edit/show views).

To run tests, install the [redmine_base_rspec](https://github.com/jbbarth/redmine_base_rspec) plugin.

## Test status

| Plugin branch | Redmine Version | Test Status       |
|---------------|-----------------|-------------------|
| master        | 6.0.8           | [![6.0.8 ][1]][5] |
| master        | 6.1.1           | [![6.1.1][2]][5]  |
| master        | master          | [![master][4]][5] |

[1]: https://github.com/nanego/redmine_admin_activity/actions/workflows/6_0_8.yml/badge.svg
[2]: https://github.com/nanego/redmine_admin_activity/actions/workflows/6_1_1.yml/badge.svg
[3]: https://github.com/nanego/redmine_admin_activity/actions/workflows/master.yml/badge.svg
[5]: https://github.com/nanego/redmine_admin_activity/actions
