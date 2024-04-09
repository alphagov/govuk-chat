RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  delegate :helpers, to: ConversationsController

  it_behaves_like "requires user to have accepted chat risks", routes: { new_conversation_path: %i[get], create_conversation_path: %i[post] }
  it_behaves_like "requires user to have accepted chat risks", routes: { show_conversation_path: %i[get], update_conversation_path: %i[patch] } do
    let(:route_params) { [SecureRandom.uuid] }
  end

  describe "GET :new" do
    include_context "with chat risks accepted"

    it "renders the correct fields" do
      get new_conversation_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to render_create_question_form
    end
  end

  describe "POST :create" do
    include_context "with chat risks accepted"

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

    context "when the request format is JSON" do
      it "saves the question and returns a 201 with the correct body when the params are valid" do
        post create_conversation_path,
             params: { create_question: { user_question: "How much tax should I be paying?" }, format: :json }

        question = Question.last

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to match({
          "question_html" => /app-c-conversation-message/,
          "answer_url" => answer_question_path(question.conversation, question),
          "error_messages" => [],
        })
      end

      it "returns a 422 and error messages when the user_question is invalid" do
        post create_conversation_path, params: { create_question: { user_question: "" }, format: :json }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq(
          "question_html" => nil,
          "answer_url" => nil,
          "error_messages" => ["Enter a question"],
        )
      end
    end
  end

  describe "GET :show" do
    include_context "with chat risks accepted"

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
    include_context "with chat risks accepted"
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
