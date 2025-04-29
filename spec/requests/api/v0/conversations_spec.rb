RSpec.describe "Api::V0::ConversationsController" do
  let(:conversation) { create(:conversation) }
  let(:question) { create(:question, conversation:) }

  before do
    login_as(create(:signon_user, :conversation_api))
  end

  shared_examples "responds with forbidden if user doesn't have conversation-api permission" do |path, method|
    let(:route_params) { {} }
    let(:params) { {} }

    describe "responds with forbidden if user doesn't have conversation-api permission" do
      it "returns with 403 for #{path}" do
        login_as(create(:signon_user))
        process(method.to_sym, public_send(path.to_sym, *route_params), params:, as: :json)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  it_behaves_like "responds with forbidden if user doesn't have conversation-api permission",
                  :api_v0_show_conversation_path,
                  :get do
    let(:route_params) { [SecureRandom.uuid] }
  end

  it_behaves_like "responds with forbidden if user doesn't have conversation-api permission",
                  :api_v0_answer_question_path,
                  :get do
    let(:route_params) { [SecureRandom.uuid, SecureRandom.uuid] }
  end

  it_behaves_like "responds with forbidden if user doesn't have conversation-api permission",
                  :api_v0_answer_feedback_path,
                  :post do
    let(:route_params) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:params) { { useful: true } }
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
      )
      expect(JSON.parse(response.body)).to eq(expected_response)
      expect(response).to have_http_status(:ok)
    end

    it "returns a 404 if the conversation cannot be found" do
      get api_v0_show_conversation_path(SecureRandom.uuid)

      expect(response).to have_http_status(:not_found)
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
end
