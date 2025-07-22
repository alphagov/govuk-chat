RSpec.describe AnswerAnalysisGeneration::TopicTagger, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer) { create(:answer) }
    let(:question) { answer.question }

    it "creates an analysis for the answer" do
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

      described_class.call(answer)

      expected_llm_response = {
        "id" => "msg-id",
        "content" => [{ "id" => "tool-use-id", "input" => { "primary_topic" => "business", "secondary_topic" => "benefits", "confidence" => "high", "reasoning" => "reason" }, "name" => "tagger_reasoning", "type" => "tool_use" }],
        "model" => BedrockModels.model_id(:claude_sonnet),
        "role" => "assistant",
        "stop_reason" => "tool_use",
        "type" => "message",
        "usage" => { "cache_read_input_tokens" => 20, "input_tokens" => 10, "output_tokens" => 20 },
      }
      expect(answer.reload.analysis.llm_responses["topic_tagger"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      stub_claude_messages_topic_tagger(question.message)

      described_class.call(answer)

      expect(answer.reload.analysis.metrics["topic_tagger"])
        .to eq(
          "duration" => 1.5,
          "llm_prompt_tokens" => 30,
          "llm_completion_tokens" => 20,
          "llm_cached_tokens" => 20,
          "model" => BedrockModels.model_id(:claude_sonnet),
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
      it "raises an error" do
        create(:answer_analysis, answer:)
        expect { described_class.call(answer.reload) }
          .to raise_error("Topics already generated for answer #{answer.id}")
      end
    end
  end
end
