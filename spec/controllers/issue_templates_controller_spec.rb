require 'rails_helper'

if Redmine::Plugin.installed?(:redmine_templates)
  describe IssueTemplatesController, type: :controller do

    fixtures :projects, :issue_template_projects, :issue_templates

    let!(:template) { IssueTemplate.find(1)}

    before do
      User.current = nil
      @request.session = ActionController::TestSession.new
      @request.session[:user_id] = 1
    end

    it "logs template activation/deactivation in project history" do
      # disable the template on project 2, enable it on project 1
      expect do
        patch :update, params: { id: 1, issue_template: { template_project_ids: ["1"] } }
      end.to change { JournalDetail.count }.by(2)

      expect(JournalDetail.last.prop_key).to eq('enabled_template')
      expect(JournalDetail.last.property).to eq('templates')
      expect(JournalDetail.last(2)[0].old_value).to eq(template.template_title)
      expect(JournalDetail.last(2)[0].value).to be_nil
      expect(JournalDetail.last(2)[1].value).to eq(template.template_title)
      expect(JournalDetail.last(2)[1].old_value).to be_nil
    end
  end
end
