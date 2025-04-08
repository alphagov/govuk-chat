RSpec.describe ConversationBlueprint do
  let(:conversation) { create(:conversation) }

  describe ".render_as_json" do
    context "with only a pending question" do
      it "generates the correct JSON" do
        pending_question = create(:question, conversation:)
        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at,
          answered_questions: [],
          pending_question: QuestionBlueprint.render_as_hash(pending_question, view: :pending),
        }.as_json

        output_json = described_class.render_as_json(
          conversation,
          answered_questions: [],
          pending_question: pending_question,
        )

        expect(output_json).to eq(expected_json)
      end
    end

    context "with answered questions and a pending question" do
      it "generates the correct JSON" do
        pending_question = create(:question, conversation:)
        answered_question1 = create(:question, :with_answer, conversation:)
        answered_question2 = create(:question, :with_answer, conversation:)

        answered_questions = Question.where(id: [answered_question1.id, answered_question2.id])
                                     .includes(answer: %i[sources feedback])
        pending_question = Question.includes(answer: %i[sources feedback]).find(pending_question.id)

        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at,
          answered_questions: answered_questions.map do |q|
            QuestionBlueprint.render_as_hash(q, view: :answered)
          end,
          pending_question: QuestionBlueprint.render_as_hash(pending_question, view: :pending),
        }.as_json

        output_json = described_class.render_as_json(
          conversation,
          answered_questions: answered_questions,
          pending_question: pending_question,
        )

        expect(output_json).to eq(expected_json)
      end
    end

    context "with no answered questions passed in" do
      it "renders an empty answered_questions array" do
        pending_question = create(:question, conversation:)

        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at,
          answered_questions: [],
          pending_question: QuestionBlueprint.render_as_hash(pending_question, view: :pending),
        }.as_json

        output_json = described_class.render_as_json(
          conversation,
          answered_questions: [],
          pending_question: pending_question,
        )

        expect(output_json).to eq(expected_json)
      end
    end

    context "with no pending question passed in" do
      it "omits pending_question from the output" do
        answered_question = create(:question, :with_answer, conversation:)
        eager_loaded_answered = Question.includes(answer: %i[sources feedback]).find(answered_question.id)

        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at,
          answered_questions: [
            QuestionBlueprint.render_as_hash(eager_loaded_answered, view: :answered),
          ],
        }.as_json

        output_json = described_class.render_as_json(
          conversation,
          answered_questions: [eager_loaded_answered],
          pending_question: nil,
        )

        expect(output_json).to eq(expected_json)
      end
    end
  end
end
