RSpec.describe AutoEvaluation::TopicTagger, :aws_credentials_stubbed do
  describe ".call" do
    let(:user_question) { "This is a test message." }
    let!(:topic_tagger_stub) { stub_bedrock_invoke_model_openai_oss_topic_tagger(user_question) }

    it "returns a results object with the expected topics" do
      result = described_class.call(user_question)
      expect(result)
        .to be_a(AutoEvaluation::TopicTagger::Result)
        .and have_attributes(
          status: "success",
          primary_topic: "business",
          secondary_topic: "benefits",
        )
    end

    it "returns a results object with the LLM response" do
      result = described_class.call(user_question)
      expected_llm_response = JSON.parse(topic_tagger_stub.response.body)
      expect(result.llm_response).to eq(expected_llm_response.to_h)
    end

    it "returns a results object with the metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      result = described_class.call(user_question)

      expect(result.metrics)
        .to eq({
          duration: 1.5,
          llm_prompt_tokens: 25,
          llm_completion_tokens: 35,
          llm_cached_tokens: 10,
          model: BedrockModels.model_id(:openai_gpt_oss_120b),
        })
    end

    it "returns an error result if an InvalidLlmResponseError is raised" do
      allow(AutoEvaluation::BedrockOpenAIOssInvoke)
        .to receive(:call)
        .and_raise(AutoEvaluation::BedrockOpenAIOssInvoke::InvalidLlmResponseError.new("invalid tool output"))

      result = described_class.call(user_question)

      expect(result).to have_attributes(
        status: "error",
        error_message: "invalid tool output",
        primary_topic: nil,
        secondary_topic: nil,
        metrics: {},
        llm_response: {},
      )
    end
  end
end
