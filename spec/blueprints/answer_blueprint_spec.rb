RSpec.describe AnswerBlueprint do
  let(:answer) { create(:answer) }

  describe ".render_as_json" do
    it "generates the correct JSON for an Answer with no sources" do
      expected_json = {
        id: answer.id,
        created_at: answer.created_at.iso8601,
        message: answer.message,
      }.as_json
      output_json = described_class.render_as_json(answer)

      expect(output_json).to eq(expected_json)
    end

    it "generates the correct JSON for an Answer with used sources" do
      answer_source = create(:answer_source, answer:)

      expected_json = {
        id: answer.id,
        created_at: answer.created_at.iso8601,
        message: answer.message,
        sources: [
          {
            title: "#{answer_source.title}: #{answer_source.heading}",
            url: answer_source.url,
          },
        ],
      }.as_json
      output_json = described_class.render_as_json(answer)

      expect(output_json).to eq(expected_json)
    end

    it "does not include unused sources in the JSON" do
      create(:answer_source, answer:, used: false)
      output_json = described_class.render_as_json(answer)
      expect(output_json.keys).not_to include("sources")
    end
  end
end
