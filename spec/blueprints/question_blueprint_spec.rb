RSpec.describe QuestionBlueprint do
  describe ".render_as_json" do
    it "generates the correct JSON for a question" do
      question = create(:question)

      expected_json = {
        id: question.id,
        conversation_id: question.conversation_id,
        created_at: question.created_at.iso8601,
        message: question.message,
      }.as_json

      expect(described_class.render_as_json(question)).to eq(expected_json)
    end

    describe "view :answered" do
      it "includes the answer" do
        question = create(:question, :with_answer)
        answer = Answer.includes(%i[sources feedback]).find(question.answer.id)

        expected_json = {
          id: question.id,
          conversation_id: question.conversation_id,
          created_at: question.created_at.iso8601,
          message: question.message,
          answer: AnswerBlueprint.render_as_hash(answer),
        }.as_json

        output_json = described_class.render_as_json(
          Question.includes(answer: %i[sources feedback]).find(question.id),
          view: :answered,
        )

        expect(output_json).to eq(expected_json)
      end
    end

    describe "view :pending" do
      it "includes the answer URL" do
        question = create(:question)

        path = Rails.application.routes.url_helpers.api_v0_answer_question_path(
          question.conversation_id,
          question.id,
        )

        expected_json = {
          id: question.id,
          conversation_id: question.conversation_id,
          created_at: question.created_at.iso8601,
          message: question.message,
          answer_url: "#{Plek.external_url_for('chat')}#{path}",
        }.as_json

        expect(described_class.render_as_json(question, view: :pending)).to eq(expected_json)
      end
    end
  end
end
