RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  delegate :helpers, to: ConversationsController

  it_behaves_like "requires user to have completed onboarding", routes: { show_conversation_path: %i[get], create_conversation_path: %i[post] }
  it_behaves_like "requires user to have completed onboarding", routes: { update_conversation_path: %i[patch] } do
    let(:route_params) { [SecureRandom.uuid] }
  end

  describe "POST :create" do
    include_context "with onboarding completed"

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

    context "when the chat API feature is enabled for specific users" do
      let(:params) { { create_question: { user_question: "How much tax should I be paying?" } } }
      let(:user_with_feature) { create(:user) }

      before { Flipper.enable(:chat_api, user_with_feature) }

      it "creates a question with the govuk_chat_api answer strategy for the specific user" do
        login_as(user_with_feature)

        expect { post create_conversation_path, params: }
          .to change { Question.answer_strategy_govuk_chat_api.count }
          .by(1)
      end

      it "creates a question with the open_ai_rag_completion strategy for a different user" do
        login_as(create(:user))

        expect { post create_conversation_path, params: }
          .to change { Question.answer_strategy_open_ai_rag_completion.count }
          .by(1)
      end
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
    include_context "with onboarding completed"

    it "renders the question form" do
      question = create(:question, :with_answer)
      get show_conversation_path(question.conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to render_create_question_form
    end

    context "when conversation_id is set on the cookie" do
      let(:conversation) { create(:conversation) }

      before do
        cookies[:conversation_id] = conversation.id
      end

      context "when the conversation has a question with an answer" do
        it "renders the question and the answer" do
          question = create(:question, :with_answer, conversation:)
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
          question = create(:question, conversation:)
          get show_conversation_path(question.conversation)

          expect(response).to have_http_status(:ok)
          expect(response.body)
            .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
        end
      end
    end
  end

  describe "PATCH :update" do
    include_context "with onboarding completed"
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
        .and have_selector(".app-c-conversation-input__label", text: "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)")
    end

    context "when the request format is JSON" do
      it "saves the question and returns a 201 with the correct body when the params are valid" do
        patch update_conversation_path(conversation),
              params: { create_question: { user_question: "How much tax should I be paying?" }, format: :json }

        question = conversation.reload.questions.last

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to match({
          "question_html" => /app-c-conversation-message/,
          "answer_url" => answer_question_path(question.conversation, question),
          "error_messages" => [],
        })
      end

      it "returns a 422 and error messages when the user_question is invalid" do
        patch update_conversation_path(conversation), params: {
          create_question: { user_question: "" },
          format: :json,
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq(
          "question_html" => nil,
          "answer_url" => nil,
          "error_messages" => ["Enter a question"],
        )
      end
    end
  end

  def render_create_question_form
    have_selector(".app-c-conversation-input__label", text: "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)")
  end
end
