RSpec.describe "Admin::QuestionsController" do
  describe "GET :index" do
    it "renders the page successfully with questions from newest to oldest" do
      oldest_question = create(:question, created_at: 1.day.ago)
      newest_question = create(:question, created_at: 1.minute.ago)

      get admin_questions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-title__text", text: "Questions")
      expect(response.body).to have_selector(".govuk-table__body .govuk-table__row:nth-child(1)", text: /#{newest_question.message}/)
      expect(response.body).to have_selector(".govuk-table__body .govuk-table__row:nth-child(2)", text: /#{oldest_question.message}/)
    end

    context "when there are more than 25 questions" do
      before do
        create_list(:question, 26)
      end

      it "paginates correctly on page 1" do
        get admin_questions_path

        expect(response.body)
          .to have_selector(".govuk-pagination__link[href='#{admin_questions_path(page: 2)}']", text: "Next page")
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_questions_path(page: "2")

        expect(response.body)
          .to have_selector(".govuk-pagination__link[href='#{admin_questions_path(page: 1)}']", text: "Previous page")
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end
    end
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
