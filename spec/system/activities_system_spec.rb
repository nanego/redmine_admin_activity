require "rails_helper"

RSpec.describe "activities", type: :system do
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :issue_statuses, :issues, :custom_fields_trackers,
           :journals, :journal_details

  before do
    log_user('admin', 'admin')
  end

  describe "issue category journal" do
    it "does not show JS alert when adding a category (XSS proof)" do
      visit "/projects/ecookbook/issue_categories/new"
      fill_in "Name", with: "<script>alert('xss')</script>"

      # expect no javascript alert is rendered
      expect do
        accept_alert wait: 2 do
          click_on "Create"
        end
      end.to raise_error(Capybara::ModalNotFound)
      expect(page).to have_content('Successful creation.')
    end

    it "is correctly javascript escaped on 'update event' (XSS proof)" do
      category = IssueCategory.create!(project: Project.find('ecookbook'), name: 'myIssue')

      visit "/issue_categories/#{category.id}/edit"
      fill_in "Name", with: "<script>alert('xss')</script>"

      # expect no javascript alert is rendered
      expect do
        accept_alert wait: 2 do
          click_on "Save"
        end
      end.to raise_error(Capybara::ModalNotFound)
      expect(page).to have_content('Successful update.')
    end

    it "is correctly javascript escaped on 'destroy event' (XSS proof)" do
      category = IssueCategory.create!(project: Project.find('ecookbook'), name: "<script>alert('xss')</script>")

      visit "/projects/ecookbook/settings/categories"
      delete_button = page.find("a[data-method='delete'][href='/issue_categories/#{category.id}']")

      # expect no javascript alert is rendered
      expect do
        accept_alert wait: 2 do
          accept_alert do
            delete_button.click
          end
        end
      end.to raise_error(Capybara::ModalNotFound)
      expect(IssueCategory.where(name: "<script>alert('xss')</script>")).to be_empty
    end
  end
end
