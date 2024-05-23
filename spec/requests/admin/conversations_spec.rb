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

    context "when there are more than 25 questions" do
      let(:conversation) { create(:conversation) }

      before do
        create_list(:question, 26, conversation:)
      end

      it "paginates correctly on page 1" do
        get admin_show_conversation_path(conversation)

        expect(response.body)
          .to have_link("Next page", href: admin_show_conversation_path(conversation, page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_show_conversation_path(conversation, page: "2")

        expect(response.body)
          .to have_link("Previous page", href: admin_show_conversation_path(conversation))
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end
    end
  end
end
