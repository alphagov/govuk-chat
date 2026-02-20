RSpec.describe AutoEvaluation::TopicTagger, :aws_credentials_stubbed do
  describe ".call" do
    let(:message) { "This is a test message." }

    before { stub_claude_messages_topic_tagger(message) }

    it "returns a results object with the expected topics" do
      result = described_class.call(message)
      expect(result)
        .to be_a(AutoEvaluation::TopicTagger::Result)
        .and have_attributes(
          primary_topic: "business",
          secondary_topic: "benefits",
        )
    end

    it "returns a results object with the LLM response" do
      result = described_class.call(message)

      expected_content = claude_messages_tool_use_block(
        input: { primary_topic: "business", reasoning: "reason", secondary_topic: "benefits" },
        name: "tagger_reasoning",
      )
      expected_llm_response = claude_messages_response(
        content: [expected_content],
        usage: { cache_read_input_tokens: 20 },
        stop_reason: :tool_use,
      ).to_h
      expect(result.llm_response).to eq(expected_llm_response.to_h)
    end

    it "returns a results object with the metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      result = described_class.call(message)

      expect(result.metrics)
        .to eq({
          duration: 1.5,
          llm_prompt_tokens: 30,
          llm_completion_tokens: 20,
          llm_cached_tokens: 20,
          model: BedrockModels.model_id(:claude_sonnet_4_0),
        })
    end
  end
end
