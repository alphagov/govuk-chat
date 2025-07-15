module AnswerComposition
  module Pipeline
    class OutputGuardrails
      def initialize(llm_provider: :openai)
        @llm_provider = llm_provider
      end

    protected

      attr_reader :llm_provider

      def build_metrics(start_time, response_or_error)
        {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: response_or_error.llm_prompt_tokens,
          llm_completion_tokens: response_or_error.llm_completion_tokens,
          llm_cached_tokens: response_or_error.llm_cached_tokens,
          model: response_or_error.model,
        }
      end

      def generate_response(context)
        result = ::Guardrails::MultipleChecker.call(context.answer.message, guardrail_name, llm_provider)
        context.answer.assign_llm_response(guardrail_name, result.llm_response)
        result
      end

      def guardrail_name
        self.class.name.split("::").last.underscore
      end

      def abort_after_response_error(context, error, start_time, message)
        context.abort_pipeline!(
          message:,
          status: "error_#{guardrail_name}",
          "#{guardrail_name}_status": :error,
          metrics: { guardrail_name => build_metrics(start_time, error) },
          llm_response: { guardrail_name => error.llm_response },
        )
      end
    end
  end
end
