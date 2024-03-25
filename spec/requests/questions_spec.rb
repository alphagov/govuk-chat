RSpec.describe "QuestionsController" do
  describe "GET :answer" do
    let(:conversation) { create(:conversation) }

    delegate :helpers, to: QuestionsController

    it "redirects to the conversation page when there are no pending answers and the user has clicked on the refresh button" do
      question = create(:question, :with_answer, conversation:)
      get answer_question_path(conversation, question, refresh: true)

      assert_redirected_to show_conversation_path(conversation, anchor: helpers.dom_id(question.answer))
      follow_redirect!
      assert_select ".gem-c-label", text: "Enter a question"
    end

    it "renders the pending page when a question doesn't have an answer" do
      question = create(:question, conversation:)
      get answer_question_path(conversation, question)

      assert_response 202
      assert_select ".govuk-notification-banner__heading", text: "GOV.UK Chat is generating an answer"
      assert_select ".govuk-button[href='#{answer_question_path(conversation, question)}?refresh=true']", text: "Check if an answer has been generated"
    end

    context "when the refresh query string is passed" do
      it "renders the pending page and thanks them for their patience" do
        question = create(:question, conversation:)
        get answer_question_path(conversation, question, refresh: true)

        assert_response 202
        assert_select ".govuk-govspeak p", text: "Thanks for your patience. Check again to find out if your answer is ready."
      end
    end
  end
end
