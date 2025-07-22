RSpec.describe AnswerInsights::TopicTagger, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer) { create(:answer) }
    let(:question) { answer.question }

    it "creates a new analysis for the answer" do
      stub_claude_messages_topic_tagger(question.message)
      expect { described_class.call(answer) }.to change(AnswerAnalysis, :count).by(1)
      expect(answer.reload.analysis)
        .to have_attributes(
          primary_topic: "business",
          secondary_topic: "benefits",
        )
    end

    it "stores the LLM response" do
      stub_claude_messages_topic_tagger(question.message)

      analysis = described_class.call(answer)

      expected_llm_response = {
        "id" => "msg-id",
        "content" => [{ "id" => "tool-use-id", "input" => { "primary_topic" => "business", "secondary_topic" => "benefits", "confidence" => "high", "reasoning" => "reason" }, "name" => "topic_tagger", "type" => "tool_use" }],
        "model" => BedrockModels::CLAUDE_SONNET,
        "role" => "assistant",
        "stop_reason" => "tool_use",
        "type" => "message",
        "usage" => { "cache_read_input_tokens" => 20, "input_tokens" => 10, "output_tokens" => 20 },
      }
      expect(analysis.llm_responses["topic_tagger"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      stub_claude_messages_topic_tagger(question.message)

      analysis = described_class.call(answer)

      expect(analysis.metrics["topic_tagger"])
        .to eq(
          "duration" => 1.5,
          "llm_prompt_tokens" => 30,
          "llm_completion_tokens" => 20,
          "llm_cached_tokens" => 20,
          "model" => BedrockModels::CLAUDE_SONNET,
        )
    end

    context "when the answer has a rephrased_question" do
      let(:rephrased_question) { "This is a rephrased_question" }

      it "uses the rephrased question for topic tagging" do
        answer = create(:answer, rephrased_question:)
        stub_claude_messages_topic_tagger(rephrased_question)
        expect { described_class.call(answer) }.to change(AnswerAnalysis, :count).by(1)
      end
    end

    context "when the answer already has a primary topic" do
      it "logs a warning" do
        create(:answer_analysis, answer:)
        allow(Rails.logger).to receive(:warn)
        described_class.call(answer.reload)
        expect(Rails.logger)
          .to have_received(:warn)
          .with("Topics already generated for answer #{answer.id}")
      end
    end
  end
end
