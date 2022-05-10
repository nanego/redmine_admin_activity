Deface::Override.new :virtual_path => 'users/edit',
                        :name => 'add-link-history-to-user-edit',
                        :insert_before => "erb[loud]:contains(\"l(:label_profile)\")",
                        :text => <<Link
<%= link_to(l(:label_history), history_user_path(@user), :class => 'icon icon-time') if User.current.admin? || User.current.try(:instance_manager?) %>
Link
