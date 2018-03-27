require "spec_helper"

describe "IssuesHelperPatch" do
  include ApplicationHelper
  include IssuesHelper
  include CustomFieldsHelper
  include ERB::Util
  include ActionView::Helpers::TagHelper

  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :projects_trackers,
           :roles,
           :member_roles,
           :members,
           :enabled_modules,
           :custom_fields,
           :attachments,
           :versions

  before do
    set_language_if_valid('en')
    User.current = nil
  end

  ### custom tests for 'modules' property

  it "should IssuesHelper#show_detail with no_html should show a changing enabled modules" do
    detail = JournalDetail.new(:property => 'modules', :old_value => ['module1'], :value => ['module1', 'module2'], :prop_key => 'modules')
    expect(show_detail(detail, true)).to eq "Enabled modules changed: removed [[\"module1\"]] and added [[\"module1\",  \"module2\"]]"
  end

  it "should IssuesHelper#show_detail with no_html should show a deleted enabled modules" do
    detail = JournalDetail.new(:property => 'modules', :old_value => ['module1'], :value => nil, :prop_key => 'modules')
    expect(show_detail(detail, true)).to eq "Enabled modules changed: removed [[\"module1\"]]  "
  end

  it "should IssuesHelper#show_detail with html should show a new enabled module with HTML highlights" do
    detail = JournalDetail.new(:property => 'modules', :old_value => nil, :value => ['module1'], :prop_key => 'modules')
    detail.id = 1
    result = show_detail(detail, false)
    expect(result).to include("Enabled modules changed:  added [[\"module1\"]]")
  end

  it "should IssuesHelper#show_detail with html should show a deleted enabled modules with HTML highlights" do
    detail = JournalDetail.new(:property => 'modules', :old_value => ['module1'], :value => nil, :prop_key => 'modules')
    html = show_detail(detail, false)
    expect(html).to include("Enabled modules changed: removed [[\"module1\"]]")
  end

  it "should IssuesHelper#show_detail with html should show all new enabled modules with HTML highlights" do
    detail = JournalDetail.new(:property => 'modules', :old_value => nil, :value => ['module1', 'module2'], :prop_key => 'modules')
    detail.id = 1
    result = show_detail(detail, false)
    html = "Enabled modules changed:  added [[\"module1\",  \"module2\"]]"
    expect(result).to include(html)
  end

  it "should IssuesHelper#show_detail with html should show all deleted enabled modules with HTML highlights" do
    detail = JournalDetail.new(:property => 'modules', :old_value => ['module1', 'module2'], :value => nil, :prop_key => 'modules')
    result = show_detail(detail, false)
    html = "Enabled modules changed: removed [[\"module1\",  \"module2\"]]"
    expect(result).to include(html)
  end


end
