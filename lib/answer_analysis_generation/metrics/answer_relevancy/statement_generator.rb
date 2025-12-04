module AnswerAnalysisGeneration::Metrics::AnswerRelevancy
  class StatementGenerator
    Result = Data.define(
      :statements,
      :llm_response,
      :metrics,
    )

    def self.call(...) = new(...).call

    def initialize(answer_message:)
      @answer_message = answer_message
    end

    def call
      start_time = Clock.monotonic_time
      client_response = BedrockConverseClient.converse(system_prompt)
      llm_response = client_response.llm_response
      statements = client_response.text_content["statements"]
      metrics = {
        duration: Clock.monotonic_time - start_time,
        model: AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::MODEL,
        llm_prompt_tokens: llm_response["usage"]["input_tokens"],
        llm_completion_tokens: llm_response["usage"]["output_tokens"],
      }
      Result.new(statements:, llm_response: llm_response.to_h, metrics:)
    end

  private

    attr_reader :answer_message

    def llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
    end

    def system_prompt
      sprintf(
        llm_prompts["statements"]["system_prompt"],
        answer: answer_message,
      )
    end
  end
end
