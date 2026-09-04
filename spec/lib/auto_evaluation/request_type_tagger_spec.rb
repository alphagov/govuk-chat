RSpec.describe AutoEvaluation::RequestTypeTagger, :aws_credentials_stubbed do
  describe ".call" do
    let(:user_question) { "This is a test message." }
    let!(:request_type_tagger_stub) { stub_bedrock_invoke_model_openai_oss_request_type_tagger(user_question) }

    it "returns a results object with the expected request types" do
      result = described_class.call(user_question)
      expect(result)
        .to be_a(AutoEvaluation::RequestTypeTagger::Result)
        .and have_attributes(
          status: "success",
          primary_request_type: "factual_lookup",
          secondary_request_type: "do_task",
          confidence: 0.9,
          reasoning: "reason",
        )
    end

    context "when the LLM does not return a secondary label" do
      let!(:request_type_tagger_stub) do
        stub_bedrock_invoke_model_openai_oss_request_type_tagger(
          user_question,
          llm_response: {
            primary_label: "FACTUAL_LOOKUP",
            secondary_label: nil,
            confidence: 0.9,
            reasoning: "reason",
          },
        )
      end

      it "returns a results object without a secondary request type" do
        result = described_class.call(user_question)
        expect(result).to have_attributes(
          primary_request_type: "factual_lookup",
          secondary_request_type: nil,
        )
      end
    end

    it "returns a results object with the LLM response" do
      result = described_class.call(user_question)
      expected_llm_response = JSON.parse(request_type_tagger_stub.response.body)
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
        primary_request_type: nil,
        secondary_request_type: nil,
        confidence: nil,
        reasoning: nil,
        metrics: {},
        llm_response: {},
      )
    end
  end
end
