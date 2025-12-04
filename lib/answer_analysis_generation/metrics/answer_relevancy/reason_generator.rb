module AnswerAnalysisGeneration::Metrics::AnswerRelevancy
  class ReasonGenerator
    Result = Data.define(
      :reason,
      :llm_response,
      :metrics,
    )

    def self.call(...) = new(...).call

    def initialize(question_message:, verdicts:, score:)
      @question_message = question_message
      @verdicts = verdicts
      @score = score
    end

    def call
      start_time = Clock.monotonic_time
      client_response = AnswerAnalysisGeneration::Metrics::BedrockConverseClient.converse(system_prompt)
      llm_response = client_response.llm_response
      reason = client_response.text_content["reason"]
      metrics = {
        duration: Clock.monotonic_time - start_time,
        model: AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::MODEL,
        llm_prompt_tokens: llm_response["usage"]["input_tokens"],
        llm_completion_tokens: llm_response["usage"]["output_tokens"],
      }

      Result.new(reason:, llm_response: llm_response.to_h, metrics:)
    end

  private

    attr_reader :question_message, :verdicts, :score

    def llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
    end

    def system_prompt
      sprintf(
        llm_prompts["reason"]["system_prompt"],
        score:,
        unsuccessful_verdicts_reasons:,
        question: question_message,
      )
    end

    def unsuccessful_verdicts_reasons
      verdicts.select { |verdict| verdict["verdict"].strip.downcase == "no" }
              .map { |verdict| verdict["reason"] }
    end
  end
end
