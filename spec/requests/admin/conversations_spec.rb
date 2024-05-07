RSpec.describe "Admin::ConversationsController" do
  describe "GET :show" do
    it "renders the page successfully with questions from newest to oldest" do
      conversation = create(:conversation)
      oldest_question = create(:question, conversation:, created_at: 1.day.ago)
      newest_question = create(:question, conversation:, created_at: 1.minute.ago)

      get admin_show_conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-title__text", text: "Conversation")
      expect(response.body).to have_selector(".govuk-table__body .govuk-table__row:nth-child(1)", text: /#{newest_question.message}/)
      expect(response.body).to have_selector(".govuk-table__body .govuk-table__row:nth-child(2)", text: /#{oldest_question.message}/)
    end
  end
end
