if defined?(Deface)
  Deface::Override.new :virtual_path => 'users/show',
                       :name => 'add-link-history-to-user-show',
                       :insert_before => "erb[loud]:contains(\"l(:button_edit)\")",
                       :text => <<~Link
                         <%= link_to(sprite_icon('time', l(:label_history)), history_user_path(@user)) if User.current.admin? || User.current.try(:instance_manager?) %>
                       Link
end
