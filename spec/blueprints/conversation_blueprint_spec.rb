RSpec.describe ConversationBlueprint do
  let(:conversation) { create(:conversation) }

  describe ".render_as_json" do
    context "with only a pending question" do
      it "generates the correct JSON" do
        pending_question = create(:question, conversation:)

        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at.iso8601,
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
        answered_questions = [
          create(:question, :with_answer, conversation:),
          create(:question, :with_answer, conversation:),
        ]

        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at.iso8601,
          answered_questions: answered_questions.map do |question|
            QuestionBlueprint.render_as_hash(question, view: :answered)
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

    context "with no pending question passed in" do
      it "omits pending_question from the output" do
        answered_question = create(:question, :with_answer, conversation:)

        expected_json = {
          id: conversation.id,
          created_at: conversation.created_at.iso8601,
          answered_questions: [
            QuestionBlueprint.render_as_hash(answered_question, view: :answered),
          ],
        }.as_json

        output_json = described_class.render_as_json(
          conversation,
          answered_questions: [answered_question],
          pending_question: nil,
        )

        expect(output_json).to eq(expected_json)
      end
    end
  end
end
