RSpec.describe "Api::V0::ConversationsController" do
  let(:conversation) { create(:conversation) }

  describe "GET :show" do
    context "when a conversation exists with the given ID" do
      it_behaves_like "adheres to the OpenAPI specification", :api_conversation_path do
        let(:route_params) { [create(:conversation)] }
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
        let!(:answered_question) { create(:question, :with_answer, conversation:) }

        it_behaves_like "adheres to the OpenAPI specification", :api_conversation_path do
          let(:route_params) { [create(:conversation)] }
        end

        it "returns the answered questions in the JSON response" do
          eager_loaded_answered_question = Question.includes(answer: %i[sources feedback]).find(answered_question.id)
          get api_conversation_path(conversation)

          expect(JSON.parse(response.body)["answered_questions"])
            .to eq([QuestionBlueprint.render_as_json(eager_loaded_answered_question, view: :answered)])
        end
      end

      context "when the conversation has a pending question" do
        let!(:pending_question) { create(:question, conversation:) }

        it_behaves_like "adheres to the OpenAPI specification", :api_conversation_path do
          let(:route_params) { [create(:conversation)] }
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
      it_behaves_like "adheres to the OpenAPI specification", :api_conversation_path, 404 do
        let(:route_params) { %w[invalid_id] }
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

  describe "POST :create" do
    let(:user_question) { "What is the capital of France?" }

    context "with valid user params" do
      it "creates a conversation and question based on the question_message param" do
        expect { post api_create_conversation_path, params: { user_question: } }
          .to change { Question.count }.by(1)
          .and change { Conversation.count }.by(1)

        expect(response).to have_http_status(:created)
        expect(Question.last.message).to eq(user_question)
      end
    end
  end
end
