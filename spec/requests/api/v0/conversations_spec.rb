RSpec.describe "Api::V0::ConversationsController" do
  let(:conversation) { create(:conversation) }
  let(:question) { create(:question, conversation:) }

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
  end
end
