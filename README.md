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
| master        | 6.1.5           | [![6.1.5][2]][5]  |
| master        | 7.0.2           | [![7.0.2][1]][5]  |
| master        | master          | [![master][3]][5] |

[1]: https://github.com/nanego/redmine_admin_activity/actions/workflows/7_0_2.yml/badge.svg
[2]: https://github.com/nanego/redmine_admin_activity/actions/workflows/6_1_5.yml/badge.svg
[3]: https://github.com/nanego/redmine_admin_activity/actions/workflows/master.yml/badge.svg
[5]: https://github.com/nanego/redmine_admin_activity/actions
