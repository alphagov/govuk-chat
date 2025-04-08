RSpec.describe AnswerSourceBlueprint do
  describe ".render_as_json" do
    it "generates the correct JSON for an AnswerSource" do
      answer_source = create(:answer_source)
      expected_json = {
        id: answer_source.id,
        title: answer_source.title,
        url: answer_source.url,
      }.as_json

      expect(described_class.render_as_json(answer_source)).to eq(expected_json)
    end
  end
end
