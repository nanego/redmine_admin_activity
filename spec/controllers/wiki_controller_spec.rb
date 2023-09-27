require 'spec_helper'

describe WikiController, type: :controller do

  render_views

  fixtures :projects, :users, :enabled_modules, :wikis, :wiki_pages, :wiki_contents, :journals, :journal_details

  include Redmine::I18n

  before do
    @controller = WikiController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 #permissions are hard
  end

  let(:project) { projects(:projects_001) }
  let(:parent_page) { wiki_pages(:wiki_pages_002) }

  describe "DELETE destroy, logs change in Journal and JournalDetail" do

    it "When we delete a page without children" do
      wiki_title = WikiPage.find(6).title

      expect do
        delete :destroy, :params => { :project_id => project.id, :id => wiki_title }
      end.to change { Journal.count }.by(1)
        .and change { JournalDetail.count }.by(1)
        .and change { WikiPage.count }.by(-1)

      expect(JournalDetail.last.old_value).to eq(wiki_title)
      expect(JournalDetail.last.prop_key).to eq("wiki_page")
      expect(JournalDetail.last.property).to eq("wiki_page")
      expect(Journal.last.journalized).to eq(project)
    end

    it "When we delete a parent page with option nullify" do
      expect do
        delete :destroy, :params => { :project_id => project.id, :id => parent_page.title, :todo => 'nullify'}
      end.to change { Journal.count }.by(1)
        .and change { JournalDetail.count }.by(1)
        .and change { WikiPage.count }.by(-1)

      expect(JournalDetail.last.old_value).to eq(parent_page.title)
      expect(JournalDetail.last.prop_key).to eq("wiki_page")
      expect(JournalDetail.last.property).to eq("wiki_page")
      expect(Journal.last.journalized).to eq(project)
    end

    it "When we delete a parent page with option destroy cascade" do
      total_size = parent_page.descendants.size + 1

      expect do
        delete :destroy, :params => {:project_id => project.id, :id => parent_page.title, :todo => 'destroy'}
      end.to change { Journal.count }.by(total_size)
        .and change { JournalDetail.count }.by(total_size)
        .and change { WikiPage.count }.by(-total_size)
    end

    it "When we delete a parent page with option reassign" do
      expect do
        delete :destroy, :params => {:project_id => project.id, :id => parent_page.title, :todo => 'reassign', :reassign_to_id => 1 }
      end.to change { Journal.count }.by(1)
        .and change { JournalDetail.count }.by(1)
        .and change { WikiPage.count }.by(-1)

      expect(JournalDetail.last.old_value).to eq(parent_page.title)
      expect(JournalDetail.last.prop_key).to eq("wiki_page")
      expect(JournalDetail.last.property).to eq("wiki_page")
      expect(Journal.last.journalized).to eq(project)
    end
  end

end
