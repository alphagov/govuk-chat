RSpec.describe "Api::V0::ConversationsController" do
  let(:api_user) { create(:signon_user, :conversation_api) }
  let(:conversation) { create(:conversation, :api, signon_user: api_user) }
  let(:question) { create(:question, conversation:) }

  before do
    login_as(api_user)
  end

  shared_examples "limits access based on permissions and conversation source" do |routes:|
    routes.each do |route|
      method = route[:method]
      path = route[:path]
      route_params = route[:route_params] || []
      params = route[:params] || {}

      describe "responds with forbidden if user doesn't have conversation-api permission" do
        before { login_as(create(:signon_user)) }

        it "returns 403 for #{method} #{path}" do
          process(
            method.to_sym,
            public_send(path.to_sym, *route_params),
            params: params,
            as: :json,
          )

          expect(response).to have_http_status(:forbidden)
        end
      end

      next if path == :api_v0_create_conversation_path

      describe "ensures the conversation was created by the API" do
        it "returns 404 when conversation source is not :api for #{method} #{path}" do
          conversation.update!(source: :web)

          process(
            method.to_sym,
            public_send(path.to_sym, *route_params),
            params: params,
            as: :json,
          )

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  it_behaves_like "limits access based on permissions and conversation source",
                  routes: [
                    {
                      path: :api_v0_create_conversation_path,
                      method: :post,
                      params: { user_question: "question" },
                    },
                    {
                      path: :api_v0_show_conversation_path,
                      method: :get,
                      route_params: [SecureRandom.uuid],
                    },
                    {
                      path: :api_v0_update_conversation_path,
                      method: :put,
                      route_params: [SecureRandom.uuid],
                      params: { user_question: "question" },
                    },
                    {
                      path: :api_v0_answer_question_path,
                      method: :get,
                      route_params: [SecureRandom.uuid, SecureRandom.uuid],
                    },
                    {
                      path: :api_v0_answer_feedback_path,
                      method: :post,
                      route_params: [SecureRandom.uuid, SecureRandom.uuid],
                      params: { useful: true },
                    },
                  ]

  it_behaves_like "throttles traffic for an access token",
                  routes: {
                    api_v0_show_conversation_path: %i[get],
                    api_v0_answer_question_path: %i[get],
                    api_v0_create_conversation_path: %i[post],
                    api_v0_update_conversation_path: %i[put],
                    api_v0_answer_feedback_path: %i[post],
                  },
                  period: 1.minute do
                    let(:route_params) do
                      {
                        conversation_id: SecureRandom.uuid,
                        question_id: SecureRandom.uuid,
                        answer_id: SecureRandom.uuid,
                      }
                    end
                  end

  it_behaves_like "throttles traffic for a single device",
                  routes: {
                    api_v0_show_conversation_path: %i[get],
                    api_v0_answer_question_path: %i[get],
                    api_v0_create_conversation_path: %i[post],
                    api_v0_update_conversation_path: %i[put],
                    api_v0_answer_feedback_path: %i[post],
                  },
                  period: 1.minute do
    let(:route_params) do
      {
        conversation_id: SecureRandom.uuid,
        question_id: SecureRandom.uuid,
        answer_id: SecureRandom.uuid,
      }
    end
  end

  describe "middleware ensures adherance to the OpenAPI specification" do
    context "when the response returned does not conform to the OpenAPI specification" do
      it "raises an error and returns the invalid params in the error message" do
        create(:answer, question:)
        allow(AnswerBlueprint).to receive(:render).and_return({}.to_json)

        get api_v0_answer_question_path(conversation, question)
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to eq({ "message" => "Internal server error" })
      end
    end

    context "when the request does not conform to the OpenAPI specification" do
      it "returns a bad request status code" do
        post api_v0_answer_feedback_path(conversation_id: conversation.id, answer_id: question.id),
             params: { useful: "not a boolean" },
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it "returns the correct JSON in the body" do
        post api_v0_answer_feedback_path(conversation_id: conversation.id, answer_id: question.id),
             params: { useful: "not a boolean" },
             as: :json
        expect(JSON.parse(response.body)).to match({ "message" => /useful expected boolean, but received String: "not a boolean"/ })
      end
    end
  end

  describe "GET :show" do
    it "returns the expected JSON" do
      pending_question = create(:question, conversation:)
      get api_v0_show_conversation_path(conversation)

      expected_response = ConversationBlueprint.render_as_json(
        conversation,
        pending_question:,
        answer_url: answer_path(pending_question),
      )
      expect(JSON.parse(response.body)).to eq(expected_response)
      expect(response).to have_http_status(:ok)
    end

    it "returns a URL to earlier questions if present" do
      allow(Rails.configuration.conversations).to receive(:api_questions_per_page).and_return(2)

      create(:question, :with_answer, conversation:, created_at: 1.minute.ago)
      oldest_in_page = create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
      create(:question, :with_answer, conversation:, created_at: 3.minutes.ago)

      get api_v0_show_conversation_path(conversation)

      earlier_questions_url = api_v0_conversation_questions_path(
        conversation, before: oldest_in_page.id
      )

      expect(JSON.parse(response.body)["earlier_questions_url"]).to eq(earlier_questions_url)
      expect(response).to have_http_status(:ok)
    end

    it "returns a 404 if the conversation cannot be found" do
      get api_v0_show_conversation_path(SecureRandom.uuid)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation has expired" do
      conversation = create(:conversation, :api, :expired, signon_user: api_user)
      get api_v0_show_conversation_path(conversation)
      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation is not associated with the user" do
      different_user = create(:signon_user, :conversation_api)
      conversation = create(:conversation, signon_user: different_user)

      get api_v0_show_conversation_path(conversation)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET :questions" do
    it "returns an empty array if there are no answered questions" do
      create(:question, conversation:)
      get api_v0_conversation_questions_path(conversation)

      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns only the answered questions" do
      create(:question, conversation:)
      questions = [
        create(:question, :with_answer, conversation:),
        create(:question, :with_answer, conversation:),
      ]

      expected_questions = Question.where(id: questions.map(&:id))
                           .includes(answer: %i[sources feedback])

      expected_response = expected_questions.map do |q|
        QuestionBlueprint.render_as_json(q, view: :answered)
      end

      get api_v0_conversation_questions_path(conversation)

      expect(JSON.parse(response.body)).to eq(expected_response)
    end

    it "limits the number of questions returned" do
      allow(Rails.configuration.conversations).to receive(:api_questions_per_page).and_return(2)
      create(:question, :with_answer, conversation:)
      create(:question, :with_answer, conversation:)
      create(:question, :with_answer, conversation:)

      get api_v0_conversation_questions_path(conversation)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns the questions before a given question ID" do
      before_question = create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
      recent_questions = [
        create(:question, :with_answer, conversation:, created_at: 6.minutes.ago),
        create(:question, :with_answer, conversation:, created_at: 5.minutes.ago),
      ]
      create(:question, :with_answer, conversation:, created_at: 1.minute.ago)

      expected_questions = Question.where(id: recent_questions.map(&:id))
                                   .includes(answer: %i[sources feedback])
      expected_response = expected_questions.map do |q|
        QuestionBlueprint.render_as_json(q, view: :answered)
      end

      get api_v0_conversation_questions_path(conversation, before: before_question.id)

      expect(JSON.parse(response.body)).to eq(expected_response)
    end

    it "returns the questions after a given question ID" do
      after_question = create(:question, :with_answer, conversation:, created_at: 10.minutes.ago)
      later_questions = [
        create(:question, :with_answer, conversation:, created_at: 9.minutes.ago),
        create(:question, :with_answer, conversation:, created_at: 8.minutes.ago),
      ]
      create(:question, :with_answer, conversation:, created_at: 20.minutes.ago)

      expected_questions = Question.where(id: later_questions.map(&:id))
                                   .includes(answer: %i[sources feedback])
      expected_response = expected_questions.map do |q|
        QuestionBlueprint.render_as_json(q, view: :answered)
      end

      get api_v0_conversation_questions_path(conversation, after: after_question.id)

      expect(JSON.parse(response.body)).to eq(expected_response)
    end

    it "returns the questions between the before and after IDs" do
      create(:question, :with_answer, conversation:, created_at: 10.minutes.ago)
      after_question = create(:question, :with_answer, conversation:, created_at: 9.minutes.ago)
      expected_question = create(:question, :with_answer, conversation:, created_at: 8.minutes.ago)
      before_question = create(:question, :with_answer, conversation:, created_at: 7.minutes.ago)
      create(:question, :with_answer, conversation:, created_at: 6.minutes.ago)

      expected_question = Question.where(id: expected_question.id)
                                 .includes(answer: %i[sources feedback])
      expected_response = QuestionBlueprint.render_as_json(expected_question, view: :answered)

      get api_v0_conversation_questions_path(
        conversation,
        before: before_question.id,
        after: after_question.id,
      )

      expect(JSON.parse(response.body)).to eq(expected_response)
    end

    it "returns a 404 if the before_id record cannot be found" do
      create(:question, :with_answer, conversation:)
      get api_v0_conversation_questions_path(conversation, before: SecureRandom.uuid)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the after_id record cannot be found" do
      create(:question, :with_answer, conversation:)
      get api_v0_conversation_questions_path(conversation, after: SecureRandom.uuid)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation cannot be found" do
      get api_v0_conversation_questions_path(conversation)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation has expired" do
      create(:conversation, :api, :expired, signon_user: api_user)
      get api_v0_show_conversation_path(SecureRandom.uuid)
      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation is not associated with the user" do
      different_user = create(:signon_user, :conversation_api)
      conversation = create(:conversation, signon_user: different_user)

      get api_v0_show_conversation_path(conversation)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST :create" do
    context "when the question is valid" do
      let(:payload) { { user_question: "What is the capital of France?" } }

      it "creates a Conversation and a Question and returns 201" do
        expect {
          post api_v0_create_conversation_path, params: payload, as: :json
        }.to change(Conversation, :count).by(1)
        .and change(Question, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns the expected json" do
        post api_v0_create_conversation_path, params: payload, as: :json

        question = Question.last
        expected_payload = QuestionBlueprint.render_as_json(
          question,
          view: :pending,
          answer_url: answer_path(question),
        )

        expect(JSON.parse(response.body)).to eq(expected_payload)
      end

      it "associates the conversation with the SignonUser" do
        post api_v0_create_conversation_path, params: payload, as: :json

        conversation = Conversation.includes(:signon_user).last
        expect(conversation.signon_user).to eq(api_user)
      end

      it "sets the conversations source to :api" do
        post api_v0_create_conversation_path, params: payload, as: :json

        conversation = Conversation.last
        expect(conversation.source).to eq("api")
      end
    end

    context "when the question is invalid" do
      let(:payload) { { user_question: "" } }

      it "returns a 422 Unprocessable Entity status" do
        post api_v0_create_conversation_path, params: payload, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the correct JSON in the body" do
        post api_v0_create_conversation_path, params: payload, as: :json

        expect(JSON.parse(response.body))
          .to eq(
            {
              "message" => "Unprocessable entity",
              "errors" => { "user_question" => [Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE] },
            },
          )
      end
    end
  end

  describe "PUT :update" do
    let(:conversation) do
      create(
        :conversation,
        :api,
        signon_user:
        api_user,
        questions: [create(:question, :with_answer)],
      )
    end

    context "when the params are valid" do
      let(:user_question) { "What is the capital of France?" }
      let(:params) { { user_question: } }

      it "returns a created status" do
        put api_v0_update_conversation_path(conversation), params:, as: :json
        expect(response).to have_http_status(:created)
      end

      it "creates a question on the conversation" do
        expect {
          put api_v0_update_conversation_path(conversation), params:, as: :json
        }.to change(conversation.questions, :count).by(1)
        expect(conversation.questions.strict_loading(false).last.message)
          .to eq(user_question)
      end

      it "returns the expected JSON" do
        put api_v0_update_conversation_path(conversation), params:, as: :json

        question = conversation.questions.strict_loading(false).last
        expected_response = QuestionBlueprint.render_as_json(
          conversation.questions.strict_loading(false).last,
          view: :pending,
          answer_url: answer_path(question),
        )
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end

    context "when the params are invalid" do
      let(:params) { { user_question: "" } }

      it "returns an unprocessable_entity status" do
        put api_v0_update_conversation_path(conversation), params:, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the correct expected JSON" do
        put api_v0_update_conversation_path(conversation), params:, as: :json

        expect(JSON.parse(response.body))
          .to eq(
            {
              "message" => "Unprocessable entity",
              "errors" => { "user_question" => [Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE] },
            },
          )
      end
    end
  end

  describe "GET :answer" do
    context "when an answer has been generated for the question" do
      let!(:answer) { create(:answer, question:) }

      it "returns a success status" do
        get api_v0_answer_question_path(conversation, question), as: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the expected JSON" do
        get api_v0_answer_question_path(conversation, question), as: :json

        eager_loaded_answer = Answer.includes(:sources, :feedback).find(answer.id)
        expected_response = AnswerBlueprint.render_as_json(eager_loaded_answer)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end

      it "returns the correct JSON for answer sources" do
        source = create(:answer_source, answer:)

        get api_v0_answer_question_path(conversation, question), as: :json

        expect(JSON.parse(response.body)["sources"])
          .to eq([{ url: source.url, title: "#{source.title}: #{source.heading}" }.as_json])
      end
    end

    context "when an answer has not been generated for the question" do
      it "returns an accepted status" do
        get api_v0_answer_question_path(conversation, question), as: :json
        expect(response).to have_http_status(:accepted)
      end

      it "returns an empty JSON response" do
        get api_v0_answer_question_path(conversation, question), as: :json
        expect(JSON.parse(response.body)).to eq({})
      end
    end
  end

  describe "POST :answer_feedback" do
    let!(:answer) { create(:answer, question:) }

    context "when the answer has no feedback" do
      it "returns a created status" do
        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }, as: :json
        expect(response).to have_http_status(:created)
      end

      it "returns an empty JSON" do
        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }, as: :json

        expect(JSON.parse(response.body)).to eq({})
      end

      it "creates feedback for the answer" do
        expect {
          post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }, as: :json
        }.to change(AnswerFeedback, :count).by(1)

        answer_feedback = AnswerFeedback.includes(:answer).last
        expect(answer_feedback.answer).to eq(answer)
        expect(answer_feedback.useful).to be true
      end
    end

    context "when an answer already has feedback" do
      before do
        create(:answer_feedback, answer:)
      end

      it "returns an unprocessable_entity status" do
        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the correct expected JSON" do
        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }, as: :json

        expect(JSON.parse(response.body))
          .to eq(
            {
              "message" => "Unprocessable entity",
              "errors" => { "base" => ["Feedback already provided for this answer"] },
            },
          )
      end
    end
  end

  def answer_path(question)
    Rails.application.routes.url_helpers.api_v0_answer_question_path(
      question.conversation_id,
      question.id,
    )
  end
end
