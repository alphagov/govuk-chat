RSpec.describe AnswerTopic::OpenAI::Tagger do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:answer) { create(:answer) }

    it "creates a new topic for the answer" do
      stub_openai_topic_tagger(answer.message)
      expect { described_class.call(answer) }.to change(AnswerTopic, :count).by(1)
      expect(answer.reload.topic)
        .to have_attributes(
          primary: "business",
          secondary: "benefits",
        )
    end

    it "stores the LLM response" do
      stub_openai_topic_tagger(answer.message)

      topic = described_class.call(answer)

      expect(topic.llm_response).to match(
        hash_including_openai_response_with_tool_call("topic_tagger"),
      )
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      stub_openai_topic_tagger(answer.message)
      topic = described_class.call(answer)

      expect(topic.metrics)
        .to eq(
          "duration" => 1.5,
          "llm_prompt_tokens" => 13,
          "llm_completion_tokens" => 7,
          "llm_cached_tokens" => 10,
          "model" => "gpt-4o-mini-2024-07-18",
        )
    end

    context "when the answer already has a topic" do
      it "logs a warning" do
        create(:answer_topic, answer:)
        allow(Rails.logger).to receive(:warn)
        described_class.call(answer.reload)
        expect(Rails.logger)
          .to have_received(:warn)
          .with("Topics already generated for answer #{answer.id}")
      end
    end
  end
end
