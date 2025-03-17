module AnswerComposition
  module Pipeline
    class JailbreakGuardrails
      def initialize(llm_provider: :openai)
        @llm_provider = llm_provider
      end

      def call(context)
        start_time = Clock.monotonic_time

        response = Guardrails::JailbreakChecker.call(context.question.message, llm_provider)
        context.answer.assign_attributes(jailbreak_guardrails_status: response.triggered ? :fail : :pass)
        context.answer.assign_llm_response("jailbreak_guardrails", response.llm_response)
        context.answer.assign_metrics("jailbreak_guardrails", build_metrics(start_time, response))

        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
            status: "guardrails_jailbreak",
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

      attr_reader :llm_provider

      def build_metrics(start_time, response_or_error)
        {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: response_or_error.llm_prompt_tokens,
          llm_completion_tokens: response_or_error.llm_completion_tokens,
          llm_cached_tokens: response_or_error.llm_cached_tokens,
        }
      end
    end
  end
end
