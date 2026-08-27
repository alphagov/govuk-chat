RSpec.describe AnswerBlueprint do
  let(:answer) { create(:answer) }
  let(:feedback_url) do
    "/api/v1/conversation/#{answer.question.conversation_id}/answers/#{answer.id}/feedback"
  end

  describe ".render_as_json" do
    it "generates the correct JSON for an Answer with no sources" do
      expected_json = {
        id: answer.id,
        created_at: answer.created_at.iso8601,
        message: answer.message,
        feedback_url:,
      }.as_json
      output_json = described_class.render_as_json(answer)

      expect(output_json).to eq(expected_json)
    end

    it "generates the correct JSON for an Answer with used sources" do
      answer_source_chunk = create(:answer_source, answer:).chunk

      expected_json = {
        id: answer.id,
        created_at: answer.created_at.iso8601,
        message: answer.message,
        sources: [
          {
            title: "#{answer_source_chunk.title}: #{answer_source_chunk.heading}",
            url: answer_source_chunk.govuk_url,
          },
        ],
        feedback_url:,
      }.as_json
      output_json = described_class.render_as_json(answer)

      expect(output_json).to eq(expected_json)
    end

    it "does not include unused sources in the JSON" do
      create(:answer_source, answer:, used: false)
      output_json = described_class.render_as_json(answer)
      expect(output_json.keys).not_to include("sources")
    end

    it "renders a relative feedback_url for the answer" do
      output_json = described_class.render_as_json(answer)

      expect(output_json["feedback_url"]).to eq(feedback_url)
      expect(output_json.keys).not_to include("feedback")
    end

    context "when the answer has feedback" do
      it "renders the feedback rather than a feedback_url" do
        feedback = create(:answer_feedback, answer:, reaction: :negative)

        output_json = described_class.render_as_json(answer.reload)

        expect(output_json["feedback"]).to eq(
          {
            reaction: "negative",
            created_at: feedback.created_at.iso8601,
          }.as_json,
        )
        expect(output_json.keys).not_to include("feedback_url")
      end
    end
  end
end
