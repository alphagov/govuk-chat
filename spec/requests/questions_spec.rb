RSpec.describe "QuestionsController" do
  it_behaves_like "requires user to have accepted chat risks", routes: { answer_question_path: %i[get] } do
    let(:route_params) { [SecureRandom.uuid, SecureRandom.uuid] }
  end

  describe "GET :answer" do
    include_context "with chat risks accepted"
    let(:conversation) { create(:conversation) }

    delegate :helpers, to: QuestionsController

    it "redirects to the conversation page when there are no pending answers and the user has clicked on the refresh button" do
      question = create(:question, :with_answer, conversation:)
      get answer_question_path(conversation, question, refresh: true)

      expected_redirect_destination = show_conversation_path(conversation, anchor: helpers.dom_id(question.answer))
      expect(response).to redirect_to(expected_redirect_destination)

      follow_redirect!
      expect(response.body)
        .to have_selector(".gem-c-label", text: "Enter a question")
    end

    it "renders the pending page when a question doesn't have an answer" do
      question = create(:question, conversation:)
      get answer_question_path(conversation, question)

      expect(response).to have_http_status(:accepted)
      expect(response.body)
        .to have_selector(".govuk-notification-banner__heading", text: "GOV.UK Chat is generating an answer")
        .and have_selector(".govuk-button[href='#{answer_question_path(conversation, question)}?refresh=true']",
                           text: "Check if an answer has been generated")
    end

    context "when the refresh query string is passed" do
      it "renders the pending page and thanks them for their patience" do
        question = create(:question, conversation:)
        get answer_question_path(conversation, question, refresh: true)

        expect(response).to have_http_status(:accepted)
        expect(response.body)
          .to have_selector(".govuk-govspeak p",
                            text: "Thanks for your patience. Check again to find out if your answer is ready.")
      end
    end
  end
end
