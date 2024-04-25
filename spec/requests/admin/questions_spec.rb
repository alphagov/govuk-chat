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
  end
end
