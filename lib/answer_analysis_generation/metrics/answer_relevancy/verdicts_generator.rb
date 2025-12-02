module AnswerAnalysisGeneration::Metrics::AnswerRelevancy
  class VerdictsGenerator
    Result = Data.define(
      :verdicts,
      :llm_response,
      :metrics,
    )

    def self.call(...) = new(...).call

    def initialize(question_message:, statements:)
      @question_message = question_message
      @statements = statements
    end

    def call
      start_time = Clock.monotonic_time
      llm_response = BedrockConverseClient.call(
        messages: [{ "role": "user", "content": [{ "text": system_prompt }] }],
      )
      metrics = {
        duration: Clock.monotonic_time - start_time,
        model: AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::MODEL,
        llm_prompt_tokens: llm_response["usage"]["input_tokens"],
        llm_completion_tokens: llm_response["usage"]["output_tokens"],
      }
      verdicts = BedrockConverseClient.parse_first_text_content_from_response(llm_response)["verdicts"]

      Result.new(verdicts:, llm_response: llm_response.to_h, metrics:)
    end

  private

    attr_reader :question_message, :statements

    def llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
    end

    def system_prompt
      sprintf(
        llm_prompts["verdicts"]["system_prompt"],
        question: question_message,
        statements: statements,
      )
    end
  end
end
