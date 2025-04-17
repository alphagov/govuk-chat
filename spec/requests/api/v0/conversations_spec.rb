RSpec.describe "Api::V0::ConversationsController" do
  let(:conversation) { create(:conversation) }
  let!(:question) { create(:question, conversation:) }

  before do
    login_as(create(:admin_user, :api_user))
  end

  describe "GET :answer" do
    context "when an answer has been generated for the question" do
      let!(:answer) { create(:answer, question:) }

      it "returns a success status" do
        get api_v0_answer_question_path(conversation, question)
        expect(response).to have_http_status(:ok)
      end

      it "returns the expected JSON" do
        get api_v0_answer_question_path(conversation, question)

        eager_loaded_answer = Answer.includes(:sources, :feedback).find(answer.id)
        expected_response = AnswerBlueprint.render_as_json(eager_loaded_answer)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end

      it "returns the correct JSON for answer sources" do
        source = create(:answer_source, answer:)

        get api_v0_answer_question_path(conversation, question)

        expect(JSON.parse(response.body)["sources"])
          .to eq([{ url: source.url, title: "#{source.title}: #{source.heading}" }.as_json])
      end
    end

    context "when an answer has not been generated for the question" do
      it "returns an accepted status" do
        get api_v0_answer_question_path(conversation, question)
        expect(response).to have_http_status(:accepted)
      end

      it "returns an empty JSON response" do
        get api_v0_answer_question_path(conversation, question)
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "when the conversation doesn't exist" do
      it "returns a not_found status" do
        get api_v0_answer_question_path("invalid-conversation-id", "invalid-question-id")
        expect(response).to have_http_status(:not_found)
      end

      it "returns the correct expected JSON" do
        get api_v0_answer_question_path("invalid-conversation-id", "invalid-question-id")
        expect(JSON.parse(response.body)).to eq({ "message" => "Conversation not found" })
      end
    end

    context "when the question doesn't exist" do
      it "returns a not_found status" do
        get api_v0_answer_question_path(conversation, "invalid-question-id")
        expect(response).to have_http_status(:not_found)
      end

      it "returns the correct expected JSON" do
        get api_v0_answer_question_path(conversation, "invalid-question-id")
        expect(JSON.parse(response.body)).to eq({ "message" => "Question not found" })
      end
    end

    context "when the user does not have the correct permissions to use the API" do
      it "returns a forbidden status" do
        login_as(create(:admin_user))
        get api_v0_answer_question_path(conversation, question)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the response returned does not conform to the OpenAPI specification" do
      it "raises an error and returns the invalid params in the error message" do
        answer = create(:answer, question:)
        eager_loaded_answer = Answer.includes(:sources, :feedback).find(answer.id)
        answer_blueprint = AnswerBlueprint.render_as_hash(eager_loaded_answer)
        answer_blueprint.delete(:created_at)
        allow(AnswerBlueprint).to receive(:render).and_return(answer_blueprint)

        expect { get api_v0_answer_question_path(conversation, question) }
          .to raise_error(Committee::InvalidResponse) do |error|
            expect(error.message).to match(/missing required parameters: created_at/)
          end
      end
    end
  end

  describe "POST :answer_feedback" do
    context "when an answer has no feedback" do
      let!(:answer) { create(:answer, question:) }

      it "returns a created status" do
        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }
        expect(response).to have_http_status(:created)
      end

      it "returns an empty JSON" do
        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }

        expect(JSON.parse(response.body)).to eq({})
      end

      it "creates feedback for the answer" do
        expect{
          post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }
      }.to change(AnswerFeedback, :count).by(1)
      
        answer_feedback = AnswerFeedback.includes(:answer).last
        expect(answer_feedback.answer).to eq(answer)
        expect(answer_feedback.useful).to be true
      end
    end

    context "when an answer already has feedback" do
      it "returns an unprocessable_entity status" do
        answer = create(:answer, question:)
        create(:answer_feedback, answer:)

        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the correct expected JSON" do
        answer = create(:answer, question:)
        create(:answer_feedback, answer:)

        post api_v0_answer_feedback_path(conversation, answer), params: { useful: true }

        expect(JSON.parse(response.body)).to eq({ "message" => "Could not save answer feedback", "fields" => { "answer_feedback" => ["Feedback already provided"] } })
      end
    end

    context "when useful parameter is missing" do
      it "returns an unprocessable_entity status" do
        answer = create(:answer, question:)

        post api_v0_answer_feedback_path(conversation, answer)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the correct expected JSON" do
        answer = create(:answer, question:)

        post api_v0_answer_feedback_path(conversation, answer)

        expect(JSON.parse(response.body)).to eq({ "message" => "Could not save answer feedback", "fields" => { "useful" => ["Useful must be true or false"] } })
      end
    end 

    context "when conversation doesn't exist" do
      it "returns a not_found status" do
        post api_v0_answer_feedback_path("invalid-conversation-id", "invalid-answer-id"), params: { useful: true }
        expect(response).to have_http_status(:not_found)
      end

      it "returns the correct expected JSON" do
        post api_v0_answer_feedback_path("invalid-conversation-id", "invalid-answer-id"), params: { useful: true }
        expect(JSON.parse(response.body)).to eq({ "message" => "Conversation not found" })
      end
    end

    context "when the answer doesn't exist" do
      it "returns a not_found status" do
        post api_v0_answer_feedback_path(conversation, "invalid-answer-id"), params: { useful: true }
        expect(response).to have_http_status(:not_found)
      end

      it "returns the correct expected JSON" do
        post api_v0_answer_feedback_path(conversation, "invalid-answer-id"), params: { useful: true }
        expect(JSON.parse(response.body)).to eq({ "message" => "Answer not found" })
      end
    end
  end
end
