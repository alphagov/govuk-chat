RSpec.describe AutoEvaluation::AnswerRelevancy::VerdictsGenerator do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:statements) { ["Statement one.", "Statement two."] }
    let(:verdicts) do
      [
        { "verdict" => "Yes" },
        { "verdict" => "No", "reason" => "The statement is irrelevant." },
      ]
    end
    let(:verdicts_json) do
      { verdicts: }.to_json
    end

    before { stub_bedrock_converse(bedrock_converse_client_response(content: verdicts_json)) }

    it "calls the AutoEvaluation::BedrockConverseAutoEvaluation with the expected prompt" do
      expected_user_prompt = sprintf(
        Rails.configuration.govuk_chat_private
                           .llm_prompts
                           .auto_evaluation
                           .answer_relevancy["verdicts"]["user_prompt"],
        question: question_message,
        statements:,
      )
      expect(AutoEvaluation::BedrockConverseAutoEvaluation).to receive(:call)
                                                           .with(expected_user_prompt)
                                                           .and_call_original

      described_class.call(question_message:, statements:)
    end

    it "returns an array with the verdicts, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(question_message:, statements:)

      expected_llm_response = bedrock_converse_client_response(content: verdicts_json).to_h
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockConverseAutoEvaluation::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        verdicts,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
