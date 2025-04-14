RSpec.describe "Api::V0::ConversationsController" do
  include Committee::Test::Methods
  let(:conversation) { create(:conversation) }

  let(:committee_options) do
    schema = Committee::Drivers.load_from_file(
      Rails.root.join("spec/support/api/openapi.yaml").to_s, parser_options: { strict_reference_validation: true }
    )

    {
      schema: schema,
      prefix: "/api/v0",
      validate_success_only: true,
    }
  end

  def request_object
    response.request
  end

  def response_data
    [response.status, response.headers, response.body]
  end

  describe "GET :show" do
    context "when a conversation exists with the given ID" do
      it "is valid against the OpenAPI spec" do
        get api_conversation_path(conversation)
        assert_response_schema_confirm(200)
      end

      it "returns a 200 response" do
        get api_conversation_path(conversation)
        expect(response).to have_http_status(:success)
      end

      it "returns the expected JSON response" do
        get api_conversation_path(conversation)
        expect(response.body).to eq(ConversationBlueprint.render(conversation))
      end

      context "when the conversation has answered questions" do
        it "returns the answered questions in the JSON response" do
          answered_question = create(:question, :with_answer, conversation:)
          eager_loaded_answered_question = Question.includes(answer: %i[sources feedback]).find(answered_question.id)
          get api_conversation_path(conversation)

          expect(JSON.parse(response.body)["answered_questions"])
            .to eq([QuestionBlueprint.render_as_json(eager_loaded_answered_question, view: :answered)])
        end
      end

      context "when the conversation has a pending question" do
        let!(:pending_question) { create(:question, conversation:) }

        it "is valid against the OpenAPI spec" do
          get api_conversation_path(conversation)
          assert_response_schema_confirm(200)
        end

        it "returns the pending question in the JSON response" do
          eager_loaded_pending_question = Question.includes(answer: %i[sources feedback]).find(pending_question.id)

          get api_conversation_path(conversation)

          expect(JSON.parse(response.body)["pending_question"])
            .to eq(QuestionBlueprint.render_as_json(eager_loaded_pending_question, view: :pending))
        end
      end
    end

    context "when a conversation does not exist with the given ID" do
      it "is valid against the OpenAPI spec" do
        get api_conversation_path(id: "invalid-id")
        assert_response_schema_confirm(404)
      end

      it "returns a 404 response" do
        get api_conversation_path(id: "invalid-id")
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message in JSON format" do
        get api_conversation_path(id: "invalid-id")
        expect(response.body)
          .to eq({ message: "Couldn't find Conversation with 'id'=invalid-id" }.to_json)
      end
    end
  end
end
