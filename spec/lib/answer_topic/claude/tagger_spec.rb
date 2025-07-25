RSpec.describe AnswerTopic::Claude::Tagger, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer) { create(:answer) }

    it "creates a new topic for the answer" do
      stub_claude_messages_topic_tagger(answer.message)
      expect { described_class.call(answer) }.to change(AnswerTopic, :count).by(1)
      expect(answer.reload.topic)
        .to have_attributes(
          primary: "business",
          secondary: "benefits",
        )
    end

    it "stores the LLM response" do
      stub_claude_messages_topic_tagger(answer.message)

      topic = described_class.call(answer)

      expected_llm_response = {
        "id" => "msg-id",
        "content" => [{ "id" => "tool-use-id", "input" => { "primary_topic" => "business", "secondary_topic" => "benefits", "confidence" => "high", "reasoning" => "reason" }, "name" => "topic_tagger", "type" => "tool_use" }],
        "model" => BedrockModels::CLAUDE_SONNET,
        "role" => "assistant",
        "stop_reason" => "tool_use",
        "type" => "message",
        "usage" => { "cache_read_input_tokens" => 20, "input_tokens" => 10, "output_tokens" => 20 },
      }
      expect(topic.llm_response).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      stub_claude_messages_topic_tagger(answer.message)

      topic = described_class.call(answer)

      expect(topic.metrics)
        .to eq(
          "duration" => 1.5,
          "llm_prompt_tokens" => 30,
          "llm_completion_tokens" => 20,
          "llm_cached_tokens" => 20,
          "model" => BedrockModels::CLAUDE_SONNET,
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
