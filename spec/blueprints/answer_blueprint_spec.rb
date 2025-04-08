RSpec.describe AnswerBlueprint do
  let(:answer) { create(:answer) }

  describe ".render_as_json"
  it "generates the correct JSON for an Answer without sources" do
    expected_json = {
      id: answer.id,
      created_at: answer.created_at.iso8601,
      message: answer.message,
    }.as_json
    output_json = described_class.render_as_json(Answer.includes(%i[sources feedback]).find(answer.id))

    expect(output_json).to eq(expected_json)
  end

  it "generates the correct JSON for an Answer with sources" do
    answer_source = create(:answer_source, answer:)
    expected_json = {
      id: answer.id,
      created_at: answer.created_at.iso8601,
      message: answer.message,
      sources: [
        AnswerSourceBlueprint.render_as_hash(answer_source),
      ],
    }.as_json
    output_json = described_class.render_as_json(Answer.includes(%i[sources feedback]).find(answer.id))

    expect(output_json).to eq(expected_json)
  end

  context "when answer feedback is present" do
    it "includes feedback in the JSON" do
      create(:answer_feedback, answer:)
      expected_json = {
        id: answer.id,
        created_at: answer.created_at.iso8601,
        message: answer.message,
        useful: true,
      }.as_json
      output_json = described_class.render_as_json(Answer.includes(%i[sources feedback]).find(answer.id))

      expect(output_json).to eq(expected_json)
    end
  end
end
