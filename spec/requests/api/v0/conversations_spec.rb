RSpec.describe "Api::V0::ConversationsController" do
  let(:conversation) { create(:conversation) }

  describe "GET :show" do
    context "when a conversation exists with the given ID" do
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
        it "returns the pending question in the JSON response" do
          pending_question = create(:question, conversation:)
          eager_loaded_pending_question = Question.includes(answer: %i[sources feedback]).find(pending_question.id)
          get api_conversation_path(conversation)

          expect(JSON.parse(response.body)["pending_question"])
            .to eq(QuestionBlueprint.render_as_json(eager_loaded_pending_question, view: :pending))
        end
      end
    end

    context "when a conversation does not exist with the given ID" do
      it "returns a 404 response" do
        get api_conversation_path(id: "invalid-id")
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message in JSON format" do
        get api_conversation_path(id: "invalid-id")
        expect(response.body).to eq({ error: "Conversation not found" }.to_json)
      end
    end
  end
end
