RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  delegate :helpers, to: ConversationsController

  it_behaves_like "requires user to have completed onboarding", routes: { show_conversation_path: %i[get], update_conversation_path: %i[post] }

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

      it "refreshes the conversation_id cookie" do
        freeze_time do
          get show_conversation_path
          expect_conversation_id_set_on_cookie(conversation)
        end
      end

      it "can render a question with an answer" do
        question = create(:question, :with_answer, conversation:)
        answer = question.answer

        get show_conversation_path(question.conversation)

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
          .and have_selector("##{helpers.dom_id(answer)} .govuk-govspeak", text: answer.message)
      end

      it "can render a question without an answer" do
        question = create(:question, conversation:)
        get show_conversation_path(question.conversation)

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
      end

      context "when the conversation cannot be found" do
        before do
          conversation.destroy!
        end

        it "deletes the conversation_id cookie" do
          get show_conversation_path
          expect(cookies[:conversation_id]).to be_blank
        end

        it "redirects to the onboarding limitations page" do
          get show_conversation_path

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(onboarding_limitations_path)
        end
      end
    end
  end

  describe "POST :update" do
    include_context "with onboarding completed"
    let(:conversation) { create(:conversation) }

    it "saves the conversation & question and renders the pending page with valid params" do
      expect { post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } } }
        .to change(Question, :count).by(1)
        .and change(Conversation, :count).by(1)
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body)
        .to have_selector(".govuk-notification-banner__heading", text: "GOV.UK Chat is generating an answer")
    end

    it "sets the converation_id cookie with valid params" do
      freeze_time do
        post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }
        expect_conversation_id_set_on_cookie(Conversation.last)
      end
    end

    it "renders the conversation with an error when the params are invalid" do
      post update_conversation_path, params: { create_question: { user_question: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body)
        .to have_selector(".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question")
        .and have_selector(".app-c-conversation-input__label", text: "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)")
    end

    context "when the converation_id cookie is present" do
      before do
        cookies[:conversation_id] = conversation.id
      end

      it "saves the question on the conversation" do
        expect { post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } } }
          .to change(Question, :count).by(1)
          .and change { conversation.reload.questions.count }.by(1)
      end

      it "refreshes the conversation_id cookie" do
        freeze_time do
          post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }
          expect_conversation_id_set_on_cookie(conversation)
        end
      end
    end

    context "when the request format is JSON" do
      before do
        cookies[:conversation_id] = conversation.id
      end

      it "saves the question and returns a 201 with the correct body when the params are valid" do
        post update_conversation_path,
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
        post update_conversation_path, params: {
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

  def expect_conversation_id_set_on_cookie(conversation)
    cookie = cookies.get_cookie("conversation_id")
    expect(cookie.value).to eq(conversation.id)
    expect(cookie.expires).to eq(7.days.from_now)
  end
end
