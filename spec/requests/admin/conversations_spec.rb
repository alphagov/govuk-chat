RSpec.describe "Admin::ConversationsController" do
  let(:conversation) { create(:conversation) }

  describe "GET :show" do
    it "renders the page successfully with questions from newest to oldest" do
      oldest_question = create(:question, conversation:, created_at: 1.day.ago)
      newest_question = create(:question, conversation:, created_at: 1.minute.ago)

      get admin_show_conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-title__text", text: "Conversation")
      expect(response.body).to have_selector(".govuk-table__body .govuk-table__row:nth-child(1)", text: /#{newest_question.message}/)
      expect(response.body).to have_selector(".govuk-table__body .govuk-table__row:nth-child(2)", text: /#{oldest_question.message}/)
    end

    context "when filter parameters are provided" do
      it "returns successfully" do
        get admin_show_conversation_path(conversation, status: "abort_forbidden_words")
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
