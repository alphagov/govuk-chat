module AnswerComposition
  module Pipeline
    class JailbreakGuardrails
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = AnswerComposition.monotonic_time

        response = Guardrails::JailbreakChecker.call(context.question.message)
        context.answer.assign_attributes(jailbreak_guardrails_status: response.triggered ? :fail : :pass)
        context.answer.assign_llm_response("jailbreak_guardrails", response.llm_response)
        context.answer.assign_metrics("jailbreak_guardrails", build_metrics(start_time, response))

        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
            status: "abort_jailbreak_guardrails",
          )
        end
      rescue Guardrails::JailbreakChecker::ResponseError => e
        context.abort_pipeline!(
          message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
          status: "error_jailbreak_guardrails",
          jailbreak_guardrails_status: :error,
          metrics: { "jailbreak_guardrails" => build_metrics(start_time, e) },
          llm_response: { "jailbreak_guardrails" => e.llm_response },
        )
      end

    private

      attr_reader :context

      def build_metrics(start_time, response_or_error)
        {
          duration: AnswerComposition.monotonic_time - start_time,
          llm_prompt_tokens: response_or_error.llm_token_usage["prompt_tokens"],
          llm_completion_tokens: response_or_error.llm_token_usage["completion_tokens"],
          llm_cached_tokens: response_or_error.llm_token_usage.dig("prompt_tokens_details", "cached_tokens"),
        }
      end
    end
  end
end
