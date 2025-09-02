RSpec.describe "Api::V1::ConversationsController" do
  let(:api_user) { create(:signon_user, :conversation_api) }
  let(:conversation) { create(:conversation, :api, signon_user: api_user, end_user_id: "user-123") }
  let(:question) { create(:question, conversation:) }
  let(:headers) { { "HTTP_GOVUK_CHAT_END_USER_ID" => "user-123" } }

  before { login_as(api_user) }

  shared_examples "uses conversation API rate limits" do |routes|
    let(:route_params) { {} }

    before do
      read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME]
      allow(read_throttle).to receive(:limit).and_return(1)
      write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        it "rate limits #{method} requests to #{path}", :rack_attack do
          process(method.to_sym, public_send(path, **route_params))
          expect(response).not_to have_http_status(:too_many_requests)
          expect(response.headers).to include(
            a_string_matching(/govuk-api-user-(read|write)-ratelimit-limit/),
            a_string_matching(/govuk-api-user-(read|write)-ratelimit-remaining/),
            a_string_matching(/govuk-api-user-(read|write)-ratelimit-reset/),
          )

          process(method.to_sym, public_send(path, **route_params))
          expect(response).to have_http_status(:too_many_requests)
          expect(response.headers).to include(
            a_string_matching(/govuk-api-user-(read|write)-ratelimit-remaining/) => "0",
          )
        end
      end
    end
  end

  shared_examples "limits access based on Signon permissions" do
    let(:method) { :get }
    let(:params) { {} }

    describe "responds with forbidden if user doesn't have conversation-api permission" do
      before { login_as(create(:signon_user)) }

      it "returns 403" do
        process(method, url, params:, headers:, as: :json)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  shared_examples "limits access based on Signon and end user permissions" do
    let(:method) { :get }
    let(:params) { {} }

    include_examples "limits access based on Signon permissions"

    describe "ensures the conversation belongs to the end user" do
      it "returns a 404 if the conversation was created by another end user" do
        conversation.update!(end_user_id: "user-456")

        process(method, url, params:, headers:, as: :json)
        expect(response).to have_http_status(:not_found)
      end
    end

    [nil, "", "    "].each do |invalid_value|
      it "responds with bad request if the end user ID header is '#{invalid_value.inspect}'" do
        headers = { "HTTP_GOVUK_CHAT_END_USER_ID" => invalid_value }
        process(method, url, params:, headers:, as: :json)
        expect(response).to have_http_status(:bad_request)
      end
    end

    it "responds with bad request if the end user ID header is missing" do
      process(method, url, params:, headers: {}, as: :json)
      expect(response).to have_http_status(:bad_request)
    end

    it "responds with bad request if the end user ID header is empty" do
      headers = { "HTTP_GOVUK_CHAT_END_USER_ID" => "     " }
      process(method, url, params:, headers:, as: :json)
      expect(response).to have_http_status(:bad_request)
    end
  end

  shared_examples "limits access based on conversation source" do
    let(:method) { :get }
    let(:params) { {} }

    describe "ensures the conversation was created by the API" do
      it "returns 404 when conversation source is not :api" do
        conversation.update!(source: :web)

        process(method, url, params:, headers:, as: :json)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  include_examples "uses conversation API rate limits",
                   {
                     api_v1_show_conversation_path: %i[get],
                     api_v1_answer_question_path: %i[get],
                     api_v1_create_conversation_path: %i[post],
                     api_v1_update_conversation_path: %i[put],
                   } do
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

        get(api_v1_answer_question_path(conversation, question), headers:)
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to eq({ "message" => "Internal server error" })
      end
    end

    context "when the request does not conform to the OpenAPI specification" do
      it "returns a bad request status code" do
        post api_v1_create_conversation_path,
             params: { user_question: 1 },
             headers:,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it "returns the correct JSON in the body" do
        post api_v1_create_conversation_path,
             params: { user_question: 1 },
             headers:,
             as: :json
        expect(JSON.parse(response.body)).to match(
          { "message" => /user_question expected string, but received Integer/ },
        )
      end
    end
  end

  describe "GET :show" do
    it_behaves_like "limits access based on Signon and end user permissions" do
      let(:url) { api_v1_show_conversation_path(conversation) }
    end

    it_behaves_like "limits access based on conversation source" do
      let(:url) { api_v1_show_conversation_path(conversation) }
    end

    it "returns the expected JSON" do
      pending_question = create(:question, conversation:)
      get(api_v1_show_conversation_path(conversation), headers:)

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

      get(api_v1_show_conversation_path(conversation), headers:)

      earlier_questions_url = api_v1_conversation_questions_path(
        conversation, before: oldest_in_page.id
      )

      expect(JSON.parse(response.body)["earlier_questions_url"]).to eq(earlier_questions_url)
      expect(response).to have_http_status(:ok)
    end

    it "returns a 404 if the conversation cannot be found" do
      get(api_v1_show_conversation_path(SecureRandom.uuid), headers:)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation has expired" do
      conversation = create(:conversation, :api, :expired, signon_user: api_user)
      get(api_v1_show_conversation_path(conversation), headers:)
      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation is not associated with the user" do
      different_user = create(:signon_user, :conversation_api)
      conversation = create(:conversation, signon_user: different_user)

      get(api_v1_show_conversation_path(conversation), headers:)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET :questions" do
    it_behaves_like "limits access based on Signon and end user permissions" do
      let(:url) { api_v1_conversation_questions_path(conversation) }
    end

    it_behaves_like "limits access based on conversation source" do
      let(:url) { api_v1_conversation_questions_path(conversation) }
    end

    it "returns an empty array if there are no answered questions" do
      create(:question, conversation:)
      expected_response = ConversationQuestions.new(
        questions: [],
      ).to_json

      get(api_v1_conversation_questions_path(conversation), headers:)

      expect(response.body).to eq(expected_response)
    end

    it "returns only the answered questions" do
      create(:question, conversation:)
      questions = [
        create(:question, :with_answer, conversation:),
        create(:question, :with_answer, conversation:),
      ]

      expected_response = ConversationQuestions.new(
        questions: questions.map { QuestionBlueprint.render_as_hash(_1, view: :answered) },
      ).to_json

      get(api_v1_conversation_questions_path(conversation), headers:)

      expect(response.body).to eq(expected_response)
    end

    it "limits the number of questions returned" do
      allow(Rails.configuration.conversations).to receive(:api_questions_per_page).and_return(2)
      create(:question, :with_answer, conversation:)
      create(:question, :with_answer, conversation:)
      create(:question, :with_answer, conversation:)

      get(api_v1_conversation_questions_path(conversation), headers:)
      expect(JSON.parse(response.body)["questions"].size).to eq(2)
    end

    it "returns the questions before a given question ID" do
      before_question = create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
      recent_questions = [
        create(:question, :with_answer, conversation:, created_at: 6.minutes.ago),
        create(:question, :with_answer, conversation:, created_at: 5.minutes.ago),
      ]
      create(:question, :with_answer, conversation:, created_at: 1.minute.ago)

      expected_response = ConversationQuestions.new(
        questions: recent_questions.map { QuestionBlueprint.render_as_hash(_1, view: :answered) },
        later_questions_url: api_v1_conversation_questions_path(conversation, after: recent_questions.last.id),
      ).to_json

      get(
        api_v1_conversation_questions_path(conversation, before: before_question.id),
        headers:,
      )

      expect(response.body).to eq(expected_response)
    end

    it "returns the questions after a given question ID" do
      after_question = create(:question, :with_answer, conversation:, created_at: 10.minutes.ago)
      later_questions = [
        create(:question, :with_answer, conversation:, created_at: 9.minutes.ago),
        create(:question, :with_answer, conversation:, created_at: 8.minutes.ago),
      ]
      create(:question, :with_answer, conversation:, created_at: 20.minutes.ago)

      expected_response = ConversationQuestions.new(
        questions: later_questions.map { QuestionBlueprint.render_as_hash(_1, view: :answered) },
        earlier_questions_url: api_v1_conversation_questions_path(conversation, before: later_questions.first.id),
      ).to_json

      get(
        api_v1_conversation_questions_path(conversation, after: after_question.id),
        headers:,
      )

      expect(response.body).to eq(expected_response)
    end

    it "returns the questions between the before and after IDs" do
      create(:question, :with_answer, conversation:, created_at: 10.minutes.ago)
      after_question = create(:question, :with_answer, conversation:, created_at: 9.minutes.ago)
      expected_question = create(:question, :with_answer, conversation:, created_at: 8.minutes.ago)
      before_question = create(:question, :with_answer, conversation:, created_at: 7.minutes.ago)
      create(:question, :with_answer, conversation:, created_at: 6.minutes.ago)

      expected_response = ConversationQuestions.new(
        questions: [QuestionBlueprint.render_as_hash(expected_question, view: :answered)],
        earlier_questions_url: api_v1_conversation_questions_path(conversation, before: expected_question.id),
        later_questions_url: api_v1_conversation_questions_path(conversation, after: expected_question.id),
      ).to_json

      get(
        api_v1_conversation_questions_path(
          conversation,
          before: before_question.id,
          after: after_question.id,
        ),
        headers:,
      )

      expect(response.body).to eq(expected_response)
    end

    context "with earlier questions" do
      before do
        allow(Rails.configuration.conversations).to(
          receive(:api_questions_per_page).and_return(2),
        )
      end

      it "returns the URL to the earlier questions" do
        create(:question, :with_answer, conversation:, created_at: 6.minutes.ago)
        oldest_question_in_page = create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
        create(:question, :with_answer, conversation:, created_at: 1.minute.ago)
        create(:question, :with_answer, conversation:, created_at: 4.minutes.ago)

        get(api_v1_conversation_questions_path(conversation), headers:)

        expect(JSON.parse(response.body)["earlier_questions_url"]).to eq(
          api_v1_conversation_questions_path(
            conversation,
            before: oldest_question_in_page.id,
          ),
        )
      end

      it "has a nil value for earlier_questions_url if there are no earlier questions" do
        create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
        create(:question, :with_answer, conversation:, created_at: 1.minute.ago)

        get(api_v1_conversation_questions_path(conversation), headers:)

        expect(JSON.parse(response.body)["earlier_questions_url"]).to be_nil
      end
    end

    context "with later questions" do
      before do
        allow(Rails.configuration.conversations).to(
          receive(:conversation_questions_per_page).and_return(2),
        )
      end

      it "returns the URL to the later questions" do
        create(:question, :with_answer, conversation:, created_at: 1.minute.ago)
        pagination_question = create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
        after_question = create(:question, :with_answer, conversation:, created_at: 3.minutes.ago)
        create(:question, :with_answer, conversation:, created_at: 4.minutes.ago)
        create(:question, :with_answer, conversation:, created_at: 5.minutes.ago)
        create(:question, :with_answer, conversation:, created_at: 6.minutes.ago)

        get(
          api_v1_conversation_questions_path(conversation, before: pagination_question.id),
          headers:,
        )

        expect(JSON.parse(response.body)["later_questions_url"]).to eq(
          api_v1_conversation_questions_path(
            conversation,
            after: after_question.id,
          ),
        )
      end

      it "has a nil value for later_questions_url if there are no later questions" do
        create(:question, :with_answer, conversation:, created_at: 2.minutes.ago)
        create(:question, :with_answer, conversation:, created_at: 1.minute.ago)

        get(api_v1_conversation_questions_path(conversation), headers:)

        expect(JSON.parse(response.body)["later_questions_url"]).to be_nil
      end
    end

    it "returns a 404 if the before_id record cannot be found" do
      create(:question, :with_answer, conversation:)
      get(
        api_v1_conversation_questions_path(conversation, before: SecureRandom.uuid),
        headers:,
      )

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the after_id record cannot be found" do
      create(:question, :with_answer, conversation:)
      get(
        api_v1_conversation_questions_path(conversation, after: SecureRandom.uuid),
        headers:,
      )

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation cannot be found" do
      get(api_v1_conversation_questions_path(conversation), headers:)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation has expired" do
      create(:conversation, :api, :expired, signon_user: api_user)
      get(api_v1_show_conversation_path(SecureRandom.uuid), headers:)
      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the conversation is not associated with the user" do
      different_user = create(:signon_user, :conversation_api)
      conversation = create(:conversation, signon_user: different_user)

      get(api_v1_show_conversation_path(conversation), headers:)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST :create" do
    it_behaves_like "limits access based on Signon permissions" do
      let(:method) { :post }
      let(:url) { api_v1_create_conversation_path }
      let(:params) { { user_question: "question" } }
    end

    context "when the question is valid" do
      let(:payload) { { user_question: "What is the capital of France?" } }

      it "creates a Conversation and a Question and returns 201" do
        expect {
          post api_v1_create_conversation_path, params: payload, headers:, as: :json
        }.to change(Conversation, :count).by(1)
        .and change(Question, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns the expected json" do
        post api_v1_create_conversation_path, params: payload, headers:, as: :json

        question = Question.last
        expected_payload = QuestionBlueprint.render_as_json(
          question,
          view: :pending,
          answer_url: answer_path(question),
        )

        expect(JSON.parse(response.body)).to eq(expected_payload)
      end

      it "associates the conversation with the SignonUser" do
        post api_v1_create_conversation_path, params: payload, headers:, as: :json

        conversation = Conversation.includes(:signon_user).last
        expect(conversation.signon_user).to eq(api_user)
      end

      it "sets the conversations source to :api" do
        post api_v1_create_conversation_path, params: payload, headers:, as: :json

        conversation = Conversation.last
        expect(conversation.source).to eq("api")
      end

      it "sets the conversation end_user_id attribute to the value in the header" do
        headers = { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-123" }
        post(api_v1_create_conversation_path, params: payload, headers:, as: :json)

        conversation = Conversation.last
        expect(conversation.end_user_id).to eq("test-user-123")
      end
    end

    context "when the question is invalid" do
      let(:payload) { { user_question: "" } }

      it "returns a 422 unprocessable content status" do
        post api_v1_create_conversation_path, params: payload, headers:, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns the correct JSON in the body" do
        post api_v1_create_conversation_path, params: payload, headers:, as: :json

        expect(JSON.parse(response.body))
          .to eq(
            {
              "message" => "Unprocessable content",
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
        signon_user: api_user,
        end_user_id: "user-123",
        questions: [create(:question, :with_answer)],
      )
    end

    it_behaves_like "limits access based on Signon and end user permissions" do
      let(:method) { :put }
      let(:url) { api_v1_update_conversation_path(conversation) }
      let(:params) { { user_question: "question" } }
    end

    it_behaves_like "limits access based on conversation source" do
      let(:method) { :put }
      let(:url) { api_v1_update_conversation_path(conversation) }
      let(:params) { { user_question: "question" } }
    end

    context "when the params are valid" do
      let(:user_question) { "What is the capital of France?" }
      let(:params) { { user_question: } }

      it "returns a created status" do
        put api_v1_update_conversation_path(conversation), params:, headers:, as: :json
        expect(response).to have_http_status(:created)
      end

      it "creates a question on the conversation" do
        expect {
          put api_v1_update_conversation_path(conversation), params:, headers:, as: :json
        }.to change(conversation.questions, :count).by(1)
        expect(conversation.questions.strict_loading(false).last.message)
          .to eq(user_question)
      end

      it "returns the expected JSON" do
        put api_v1_update_conversation_path(conversation), params:, headers:, as: :json

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

      it "returns an unprocessable_content status" do
        put api_v1_update_conversation_path(conversation), params:, headers:, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns the correct expected JSON" do
        put api_v1_update_conversation_path(conversation), params:, headers:, as: :json

        expect(JSON.parse(response.body))
          .to eq(
            {
              "message" => "Unprocessable content",
              "errors" => { "user_question" => [Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE] },
            },
          )
      end
    end
  end

  describe "GET :answer" do
    it_behaves_like "limits access based on Signon and end user permissions" do
      let(:url) { api_v1_answer_question_path(conversation, question) }
    end

    it_behaves_like "limits access based on conversation source" do
      let(:url) { api_v1_answer_question_path(conversation, question) }
    end

    context "when an answer has been generated for the question" do
      let!(:answer) { create(:answer, question:) }

      it "returns a success status" do
        get api_v1_answer_question_path(conversation, question), headers:, as: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns the expected JSON" do
        get api_v1_answer_question_path(conversation, question), headers:, as: :json

        expected_response = AnswerBlueprint.render_as_json(answer)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end

      it "returns the correct JSON for answer sources" do
        source = create(:answer_source, answer:)

        get api_v1_answer_question_path(conversation, question), headers:, as: :json

        expect(JSON.parse(response.body)["sources"])
          .to eq([{ url: source.url, title: "#{source.title}: #{source.heading}" }.as_json])
      end
    end

    context "when an answer has not been generated for the question" do
      it "returns an accepted status" do
        get api_v1_answer_question_path(conversation, question), headers:, as: :json
        expect(response).to have_http_status(:accepted)
      end

      it "returns an empty JSON response" do
        get api_v1_answer_question_path(conversation, question), headers:, as: :json
        expect(JSON.parse(response.body)).to eq({})
      end
    end
  end

  def answer_path(question)
    Rails.application.routes.url_helpers.api_v1_answer_question_path(
      question.conversation_id,
      question.id,
    )
  end
end
