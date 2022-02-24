Deface::Override.new :virtual_path => 'users/show',
                     :name => 'add-link-history-to-user-show',
                     :insert_before => "erb[loud]:contains(\"l(:button_edit)\")",
                     :text => <<Link
<%= link_to(l(:label_history), history_user_path(@user), :class => 'icon icon-time') if User.current.allowed_to?(:see_user_changes_history, nil, :global => true) %>
Link

