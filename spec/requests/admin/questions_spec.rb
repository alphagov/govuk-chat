RSpec.describe "Admin::QuestionsController" do
  it_behaves_like "a filterable table of questions in the admin interface",
                  :admin_questions_path,
                  ":index" do
    let(:conversation) { nil }
  end

  describe "GET :show" do
    it "renders the page successfully" do
      question = create(:question)
      get admin_show_question_path(question)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content(question.message)
    end

    it "renders a link to the search results page" do
      question = create(:question)
      get admin_show_question_path(question)

      expect(response.body).to have_content("Show search results")
      href = admin_search_path(params: { search_text: question.message })
      expect(response.body).to have_selector("a.govuk-link[href='#{href}']", text: question.message)
    end

    it "renders a link to the search results with rephrased question" do
      question = create(:question, :with_answer)
      question.answer.update!(rephrased_question: "how do I pay self assessment")
      get admin_show_question_path(question)

      expect(response.body).to have_content("Show search results")
      href = admin_search_path(params: { search_text: "how do I pay self assessment" })
      expect(response.body).to have_selector("a.govuk-link[href='#{href}']", text: "how do I pay self assessment")
    end
  end
end
