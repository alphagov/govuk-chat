RSpec.describe "ConversationsController" do
  delegate :helpers, to: ConversationsController
  let(:signon_user) { create(:signon_user, :web_chat) }

  before { login_as(signon_user) }

  it_behaves_like "requires a users conversation cookie to reference an active conversation",
                  routes: { clear_conversation_path: %i[get] },
                  with_json: false
  it_behaves_like "requires a users conversation cookie to reference an active conversation",
                  routes: { answer_question_path: %i[get], answer_feedback_path: %i[post] } do
    let(:route_params) { [SecureRandom.uuid] }
  end

  it_behaves_like "requires a conversation created via the chat interface", routes: { answer_question_path: %i[get], answer_feedback_path: %i[post] } do
    let(:route_params) { [SecureRandom.uuid] }
  end

  describe "GET :show" do
    context "when there is no conversation cookie" do
      it "renders a welcome message as a new message" do
        get show_conversation_path

        expect(response).to have_http_status(:success)
        expect(response.body).to have_selector(
          ".js-new-conversation-messages-list",
          text: "Hi 👋 I’m GOV.UK Chat.",
        )
      end

      it "renders the question form" do
        get show_conversation_path

        expect(response).to have_http_status(:success)
        expect(response.body).to render_create_question_form
      end

      it "renders a focusable only 'Clear chat' link" do
        get show_conversation_path

        expect(response.body).to have_selector(
          "a.app-c-header__clear-chat.app-c-header__clear-chat--focusable-only",
          text: "Clear chat",
        )
      end
    end

    context "when the conversation is active" do
      let(:conversation) { create(:conversation, :not_expired, signon_user:) }

      before do
        cookies[:conversation_id] = conversation.id
      end

      it "refreshes the conversation_id cookie" do
        freeze_time do
          get show_conversation_path
          expect_conversation_id_set_on_cookie(conversation)
        end
      end

      it "renders a welcome message in the message history" do
        get show_conversation_path

        expect(response).to have_http_status(:success)
        expect(response.body).to have_selector(
          ".js-conversation-message-history-list",
          text: "Hi 👋 I’m GOV.UK Chat",
        )
      end

      it "renders a 'Clear chat' without the focusable only modifier link" do
        get show_conversation_path

        expect(response.body).to have_selector(
          "a.app-c-header__clear-chat:not(.app-c-header__clear-chat--focusable-only)",
          text: "Clear chat",
        )
      end

      context "and there is a question without an answer" do
        let(:conversation) { create(:conversation, signon_user:) }

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
        let(:conversation) { create(:conversation, signon_user:) }

        it "renders the answer and an answer feedback form" do
          question = create(:question, :with_answer, conversation:)
          answer = question.answer

          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body)
            .to have_selector("##{helpers.dom_id(question)}", text: /#{question.message}/)
            .and have_selector("##{helpers.dom_id(answer)} .govuk-govspeak", text: answer.message)
            .and have_button("The answer to \"#{question.message}\" was Useful", name: "create_answer_feedback[useful]", value: "true")
            .and have_button("The answer was not useful", name: "create_answer_feedback[useful]", value: "false")
        end
      end

      context "and there is a question with an answer that has feedback" do
        let(:conversation) { create(:conversation, signon_user:) }

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
        let(:conversation) { create(:conversation, signon_user:) }

        it "renders the sources correctly for answers with the success status" do
          question = create(:question, conversation:)
          answer = create(:answer, :with_sources, question:)
          first_source = answer.sources.first
          second_source = answer.sources.second

          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body)
            # The following links will not be visible due to collapsed state of details element, but should be present in the DOM
            .to have_link(first_source.title, href: first_source.url, visible: :hidden)
            .and have_link(second_source.title, href: second_source.url, visible: :hidden)
        end

        it "doesn't render unused sources" do
          question = create(:question, conversation:)
          answer = create(:answer, question:)
          first_source = create(:answer_source, answer:, used: true)
          second_source = create(:answer_source, answer:, used: false)

          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body)
            .to have_link(first_source.title, href: first_source.url, visible: :hidden)
            .and have_no_link(second_source.title)
        end

        it "doesn't render the sources component if all sources are unused" do
          question = create(:question, conversation:)
          answer = create(:answer, question:)
          create(:answer_source, answer:, used: false)

          get show_conversation_path

          expect(response).to have_http_status(:success)
          expect(response.body).to have_no_selector(".app-c-conversation-sources")
        end
      end

      context "and there are more questions than the max number of questions" do
        let(:conversation) { create(:conversation, signon_user:) }

        it "only renders the max number of question from rails config" do
          allow(Rails.configuration.conversations).to receive(:max_question_count).and_return(1)
          older_question = create(:question, :with_answer, conversation:)
          question = create(:question, :with_answer, conversation:)

          get show_conversation_path

          expect(response.body).to include(question.message)
          expect(response.body).not_to include(older_question.message)
        end
      end
    end
  end

  describe "POST :update" do
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
          .to have_selector("h1", text: "GOV.UK Chat is generating an answer")
      end

      it "associates the signon user with the conversation" do
        post update_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }

        conversation = Conversation.includes(:signon_user).last
        expect(conversation.signon_user).to eq(signon_user)
      end

      context "and the params are invalid while the last question is answered" do
        it "renders the conversation with an error" do
          post update_conversation_path, params: { create_question: { user_question: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body)
            .to have_title(/^Error -/)
            .and have_selector(".govuk-error-summary a[href='#create_question_user_question']",
                               text: Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE)
            .and have_selector(".app-c-question-form__label", text: "Message")
        end
      end

      context "and the params are invalid while the last question is not answered" do
        let(:conversation) { create(:conversation, signon_user:, questions: [create(:question)]) }

        before do
          cookies[:conversation_id] = conversation.id
        end

        it "renders the conversation with a pending answer URL" do
          post update_conversation_path, params: { create_question: { user_question: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          question = conversation.questions.last
          expect(response.body)
            .to have_selector("[data-pending-answer-url='#{answer_question_path(question)}']")
        end
      end

      context "and the converation_id cookie is present" do
        let(:conversation) { create(:conversation, :not_expired, signon_user:) }

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
      let(:conversation) { create(:conversation, :not_expired, signon_user:) }

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

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to eq(
          "question_html" => nil,
          "answer_url" => nil,
          "error_messages" => [Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE],
        )
      end
    end
  end

  describe "GET :answer" do
    let(:conversation) { create(:conversation, signon_user:) }

    before do
      cookies[:conversation_id] = conversation.id
    end

    it "redirects to the conversation page when there are no pending answers and the user has clicked on the refresh button" do
      question = create(:question, :with_answer, conversation:)
      get answer_question_path(question, refresh: true)
      answer = question.answer

      expected_redirect_destination = show_conversation_path
      expect(response).to redirect_to(expected_redirect_destination)
      expect(flash[:notice]).to eq({ link_href: "##{helpers.dom_id(answer)}", link_text: "View your answer", message: "GOV.UK Chat has answered your question" })

      follow_redirect!
      expect(response.body)
        .to have_selector(".app-c-question-form__label", text: "Message")
    end

    it "renders the pending page when a question doesn't have an answer" do
      question = create(:question, conversation:)
      get answer_question_path(question)

      expect(response).to have_http_status(:accepted)
      expect(response.body)
        .to have_selector("h1", text: "GOV.UK Chat is generating an answer")
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

    context "when the answer generation has timed out" do
      let(:question) do
        create(
          :question,
          conversation:,
          created_at: Rails.configuration.conversations.answer_timeout_in_seconds.seconds.ago,
        )
      end

      it "creates the answer with a status of error_timeout" do
        expect { get answer_question_path(question) }.to change { question.reload.answer }.from(nil)
        expect(question.answer).to have_attributes(
          message: Answer::CannedResponses::TIMED_OUT_RESPONSE,
          status: "error_timeout",
        )
      end

      it "redirects to the conversation show page" do
        get answer_question_path(question)
        expect(response).to redirect_to(show_conversation_path)
      end
    end

    context "when the request format is JSON" do
      it "responds with a 200 and answer_html when the question has been answered" do
        question = create(:question, :with_answer, conversation:)

        get answer_question_path(question), params: { format: :json }

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to match({ "answer_html" => /app-c-conversation-message/ })
      end

      it "responds with an accepted status code when the question has a pending answer" do
        question = create(:question, conversation:)
        get answer_question_path(question), params: { format: :json }

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to eq({ "answer_html" => nil })
      end

      context "when the answer generation has timed out" do
        it "responds successfully with the correct JSON" do
          question = create(
            :question,
            conversation:,
            created_at: Rails.configuration.conversations.answer_timeout_in_seconds.seconds.ago,
          )

          get answer_question_path(question), params: { format: :json }

          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to match({ "answer_html" => /app-c-conversation-message/ })
        end
      end
    end
  end

  describe "POST :answer_feedback" do
    let(:conversation) { create(:conversation, signon_user:) }
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
        expect(response).to redirect_to(show_conversation_path)
        follow_redirect!
        expect(response.body).to have_selector(".govuk-notification-banner__content", text: "Feedback submitted successfully.")
      end

      it "does not persist the feedback and redirects show page when feedback is invalid" do
        answer = create(:answer, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "" } } }
          .not_to change(AnswerFeedback, :count)
        expect(response).to redirect_to(show_conversation_path)
        follow_redirect!
        expect(response.body).not_to have_selector(".govuk-notification-banner__content", text: "Feedback submitted successfully.")
      end

      it "does not persist the feedback and redirects show page when feedback is already present" do
        answer = create(:answer, :with_feedback, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "true" } } }
          .not_to change(AnswerFeedback, :count)
        expect(response).to redirect_to(show_conversation_path)
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

      it "returns an unprocessable_content response with invalid params" do
        answer = create(:answer, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: "" }, format: :json } }
          .not_to change(AnswerFeedback, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to eq({ "error_messages" => ["Useful must be true or false"] })
      end

      it "returns a unprocessable_content response when feedback is already present on the answer" do
        answer = create(:answer, :with_feedback, question:)

        expect { post answer_feedback_path(answer), params: { create_answer_feedback: { useful: true }, format: :json } }
        .not_to change(AnswerFeedback, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to eq({ "error_messages" => ["Feedback already provided for this answer"] })
      end
    end
  end

  describe "GET :clear" do
    context "when the conversation is active" do
      let(:conversation) { create(:conversation, :not_expired, signon_user:) }

      before do
        cookies[:conversation_id] = conversation.id
      end

      it "renders the clear confirmation page" do
        get clear_conversation_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector("h1", text: "Do you want to clear your chat history?")
      end
    end
  end

  describe "POST :clear" do
    context "when the conversation is active" do
      let(:conversation) { create(:conversation, :not_expired, signon_user:) }

      before do
        cookies[:conversation_id] = conversation.id
      end

      it "clears the conversation cookie" do
        post clear_conversation_path

        expect(cookies[:conversation_id]).to(be_empty)
        expect(response).to redirect_to(show_conversation_path)
      end
    end
  end

  def render_create_question_form
    have_selector(".app-c-question-form__label", text: "Message")
  end

  def expect_conversation_id_set_on_cookie(conversation)
    cookie = cookies.get_cookie("conversation_id")
    expect(cookie.value).to eq(conversation.id)
    expect(cookie.expires).to eq(90.days.from_now)
  end
end
