RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  delegate :helpers, to: ConversationsController

  describe "GET :new" do
    it "renders the correct fields" do
      get new_conversation_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to render_create_question_form
    end
  end

  describe "POST :create" do
    it "saves the question and renders pending page with valid params" do
      post create_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body)
        .to have_selector(".govuk-notification-banner__heading",
                          text: "GOV.UK Chat is generating an answer")
    end

    it "renders the new conversation page with an error when the params are invalid" do
      post create_conversation_path, params: { create_question: { user_question: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body)
        .to have_selector(".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question")
        .and render_create_question_form
    end
  end

  describe "GET :show" do
    it "renders the question form" do
      question = create(:question, :with_answer)
      get show_conversation_path(question.conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to render_create_question_form
    end

    context "when the conversation has a question with an answer" do
      it "renders the question and the answer" do
        question = create(:question, :with_answer)
        answer = question.answer

        get show_conversation_path(question.conversation)

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
          .and have_selector("##{helpers.dom_id(answer)} .govuk-govspeak", text: answer.message)
      end
    end

    context "when the conversation has an unanswered question" do
      it "only renders a question" do
        question = create(:question)
        get show_conversation_path(question.conversation)

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
      end
    end
  end

  describe "PATCH :update" do
    let(:conversation) { create(:conversation) }

    it "saves the question and renders the pending page with valid params" do
      patch update_conversation_path(conversation), params: { create_question: { user_question: "How much tax should I be paying?" } }

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body)
        .to have_selector(".govuk-notification-banner__heading", text: "GOV.UK Chat is generating an answer")
    end

    it "renders the conversation with an error when the params are invalid" do
      patch update_conversation_path(conversation), params: { create_question: { user_question: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body)
        .to have_selector(".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question")
        .and have_selector(".gem-c-label", text: "Enter a question")
    end
  end

  def render_create_question_form
    have_selector(".gem-c-label", text: "Enter a question")
  end
end
