RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  delegate :helpers, to: ConversationsController

  it_behaves_like "requires user to have completed onboarding", routes: { show_conversation_path: %i[get], update_conversation_path: %i[post] }
  it_behaves_like "requires user to have completed onboarding", routes: { answer_question_path: %i[get], answer_feedback_path: %i[post] } do
    let(:route_params) { [SecureRandom.uuid] }
  end

  describe "GET :show" do
    include_context "with onboarding completed"

    context "when there is no conversation cookie" do
      context "and the response type is HTML" do
        it "renders the question form" do
          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body).to render_create_question_form
        end
      end

      context "and the response type is JSON" do
        it "returns a success response with the correct JSON" do
          get show_conversation_path, params: { format: :json }

          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to match({
            "fragment" => "start-chatting",
            "conversation_data" => { "module" => "chat-conversation" },
            "conversation_append_html" => /<p>Thanks! To get started, ask me a question.<\/p>/,
            "form_html" => /<button class="app-c-blue-button govuk-button app-c-blue-button--conversation-form js-conversation-form-button">Send<\/button/,
          })
        end
      end
    end

    context "when the conversation cannot be found" do
      before do
        cookies[:conversation_id] = "unknown-id"
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

    context "when the conversation cookie has expired" do
      let(:conversation) { create(:conversation, :expired) }

      before do
        cookies[:conversation_id] = conversation.id
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

    context "when the conversation is active" do
      let(:conversation) { create(:conversation, :not_expired) }

      before do
        cookies[:conversation_id] = conversation.id
      end

      it "refreshes the conversation_id cookie" do
        freeze_time do
          get show_conversation_path
          expect_conversation_id_set_on_cookie(conversation)
        end
      end

      context "and there is a question without an answer" do
        let(:conversation) { create(:conversation) }

        it "renders the question and pending answer url correctly" do
          question = create(:question, conversation:)
          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body)
            .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
            .and have_selector("[data-pending-answer-url='#{answer_question_path(question)}']")
        end
      end

      context "and there is a question with an answer that doesn't have feedback" do
        let(:conversation) { create(:conversation) }

        it "renders the answer and an answer feedback form" do
          question = create(:question, :with_answer, conversation:)
          answer = question.answer

          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body)
            .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
            .and have_selector("##{helpers.dom_id(answer)} .govuk-govspeak", text: answer.message)
            .and have_button("Useful", name: "create_answer_feedback[useful]", value: "true")
            .and have_button("not useful", name: "create_answer_feedback[useful]", value: "false")
        end
      end

      context "and there is a question with an answer that has feedback" do
        let(:conversation) { create(:conversation) }

        it "doesn't render a feedback form" do
          question = create(:question, :with_answer, conversation:)
          create(:answer_feedback, answer: question.answer)

          get show_conversation_path
          expect(response).to have_http_status(:success)
          expect(response.body)
            .to have_no_button("Useful")
            .and have_no_button("not useful")
        end
      end

      context "and there is a question with an answer that has sources" do
        let(:conversation) { create(:conversation) }

        it "renders the sources correctly" do
          question = create(:question, conversation:)
          answer = create(:answer, :with_sources, question:)
          first_source = answer.sources.first
          second_source = answer.sources.second

          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body)
            .to have_link(first_source.title, href: first_source.url)
            .and have_link(second_source.title, href: second_source.url)
        end
      end

      context "and there are more questions than the max number of questions" do
        let(:conversation) { create(:conversation) }

        it "only renders the max number of question from rails config" do
          allow(Rails.configuration.conversations).to receive(:max_question_count).and_return(1)
          older_question = create(:question, :with_answer, conversation:)
          question = create(:question, :with_answer, conversation:)

          get show_conversation_path

          expect(response.body).to include(question.message)
          expect(response.body).not_to include(older_question.message)
        end
      end

      context "and the response format is JSON" do
        before do
          conversation = create(:conversation, :not_expired)
          cookies[:conversation_id] = conversation.id
        end

        it "returns a bad request response" do
          get show_conversation_path, params: { format: :json }

          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)).to match({})
        end
      end
    end
  end

  describe "POST :update" do
    include_context "with onboarding completed"
    let(:conversation) { create(:conversation, :not_expired) }

    it "sets the converation_id cookie with valid params" do
      freeze_time do
        post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }
        expect_conversation_id_set_on_cookie(Conversation.last)
      end
    end

    context "when the response type is HTML" do
      it "saves the conversation & question and renders the pending page with valid params" do
        expect { post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } } }
          .to change(Question, :count).by(1)
          .and change(Conversation, :count).by(1)
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response.body)
          .to have_selector(".gem-c-title__text", text: "GOV.UK Chat is generating an answer")
      end

      it "renders the conversation with an error when the params are invalid" do
        post update_conversation_path, params: { create_question: { user_question: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body)
          .to have_selector(".govuk-error-summary a[href='#create_question_user_question']",
                            text: Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE)
          .and have_selector(".app-c-conversation-form__label", text: "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)")
      end

      context "and the converation_id cookie is present" do
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
    end

    context "when the request format is JSON" do
      before do
        cookies[:conversation_id] = conversation.id
      end

      it "saves the question and returns a 201 with the correct body when the params are valid" do
        post update_conversation_path,
             params: { create_question: { user_question: "How much tax should I be paying?" }, format: :json }

        question = Question.where(conversation:).last

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to match({
          "question_html" => /app-c-conversation-message/,
          "answer_url" => answer_question_path(question),
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
          "error_messages" => [Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE],
        )
      end
    end
  end

  describe "GET :answer" do
    include_context "with onboarding completed"
    let(:conversation) { create(:conversation) }

    before do
      cookies[:conversation_id] = conversation.id
    end

    it "redirects to the conversation page when there are no pending answers and the user has clicked on the refresh button" do
      question = create(:question, :with_answer, conversation:)
      get answer_question_path(question, refresh: true)

      expected_redirect_destination = show_conversation_path(anchor: helpers.dom_id(question.answer))
      expect(response).to redirect_to(expected_redirect_destination)
      expect(flash[:notice]).to eq("GOV.UK Chat has answered your question")

      follow_redirect!
      expect(response.body)
        .to have_selector(".app-c-conversation-form__label", text: "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)")
    end

    it "renders the pending page when a question doesn't have an answer" do
      question = create(:question, conversation:)
      get answer_question_path(question)

      expect(response).to have_http_status(:accepted)
      expect(response.body)
        .to have_selector(".gem-c-title__text", text: "GOV.UK Chat is generating an answer")
        .and have_selector(".govuk-button[href='#{answer_question_path(question)}?refresh=true']",
                           text: "Check if an answer has been generated")
    end

    context "when the refresh query string is passed" do
      it "renders the pending page and thanks them for their patience" do
        question = create(:question, conversation:)
        get answer_question_path(question, refresh: true)

        expect(response).to have_http_status(:accepted)
        expect(response.body)
          .to have_selector(".govuk-body",
                            text: "Thanks for your patience. Check again to find out if your answer is ready.")
      end
    end

    context "when the request format is JSON" do
      it "responds with a 200 and answer_html when the question has been answered" do
        question = create(:question, :with_answer, conversation:)

        get answer_question_path(question, format: :json)

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to match({ "answer_html" => /app-c-conversation-message/ })
      end

      it "responds with an accepted status code when the question has a pending answer" do
        question = create(:question, conversation:)
        get answer_question_path(question, format: :json)

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to eq({ "answer_html" => nil })
      end
    end
  end

  describe "POST :answer_feedback" do
    include_context "with onboarding completed"
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }

    before do
      cookies[:conversation_id] = conversation.id
    end

    it "sets the converation_id cookie with valid params" do
      answer = create(:answer, question:)

      freeze_time do
        post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "true" } }
        expect_conversation_id_set_on_cookie(conversation)
      end
    end

    context "when the response format is HTML" do
      it "saves the answer feedback and redirects to the show page with valid params" do
        create(:answer, question:)
        answer = Answer.includes(:feedback).last

        post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "false" } }

        expect(answer.reload.feedback.useful).to be(false)
        expect(response).to redirect_to(show_conversation_path(anchor: helpers.dom_id(answer)))
        follow_redirect!
        expect(response.body).to have_selector(".govuk-notification-banner__content", text: "Feedback submitted successfully.")
      end

      it "does not persist the feedback and redirects show page when feedback is invalid" do
        answer = create(:answer, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "" } } }
          .not_to change(AnswerFeedback, :count)
        expect(response).to redirect_to(show_conversation_path(anchor: helpers.dom_id(answer)))
        follow_redirect!
        expect(response.body).not_to have_selector(".govuk-notification-banner__content", text: "Feedback submitted successfully.")
      end

      it "does not persist the feedback and redirects show page when feedback is already present" do
        answer = create(:answer, :with_feedback, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "true" } } }
          .not_to change(AnswerFeedback, :count)
        expect(response).to redirect_to(show_conversation_path(anchor: helpers.dom_id(answer)))
        follow_redirect!
        expect(response.body).not_to have_selector(".govuk-notification-banner__content", text: "Feedback submitted successfully.")
      end
    end

    context "when the response format is JSON" do
      it "creates the feedback and returns a created response with valid params" do
        create(:answer, question:)
        answer = Answer.includes(:feedback).last

        post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "false" }, format: :json }

        expect(answer.reload.feedback.useful).to be(false)
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq({ "error_messages" => [] })
      end

      it "returns an unprocessable_entity response with invalid params" do
        answer = create(:answer, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "" }, format: :json } }
          .not_to change(AnswerFeedback, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "error_messages" => ["Useful must be true or false"] })
      end

      it "returns a unprocessable_entity response when feedback is already present on the answer" do
        answer = create(:answer, :with_feedback, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: true }, format: :json } }
        .not_to change(AnswerFeedback, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "error_messages" => ["Feedback already provided"] })
      end
    end
  end

  def render_create_question_form
    have_selector(".app-c-conversation-form__label", text: "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)")
  end

  def expect_conversation_id_set_on_cookie(conversation)
    cookie = cookies.get_cookie("conversation_id")
    expect(cookie.value).to eq(conversation.id)
    expect(cookie.expires).to eq(30.days.from_now)
  end
end
