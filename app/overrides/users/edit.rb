if defined?(Deface)
  Deface::Override.new :virtual_path => 'users/edit',
                       :name => 'add-link-history-to-user-edit',
                       :insert_before => "erb[loud]:contains(\"l(:label_profile)\")",
                       :text => <<~Link
                         <%= link_to(sprite_icon('time', l(:label_history)), history_user_path(@user)) if User.current.admin? || User.current.try(:instance_manager?) %>
                       Link
end
