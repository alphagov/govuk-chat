module AnswerComposition
  module Pipeline
    class OutputGuardrails
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

    protected

      attr_reader :context

      def build_metrics(start_time, response_or_error)
        {
          duration: AnswerComposition.monotonic_time - start_time,
          llm_prompt_tokens: response_or_error.llm_token_usage["prompt_tokens"],
          llm_completion_tokens: response_or_error.llm_token_usage["completion_tokens"],
        }
      end

      def response
        @response ||= begin
          result = ::OutputGuardrails::FewShot.call(context.answer.message, guardrail_name)

          context.answer.assign_llm_response(guardrail_name, result.llm_response)

          result
        end
      end

      def guardrail_name
        self.class.name.split("::").last.underscore
      end

      def abort_after_response_error(error, start_time)
        context.abort_pipeline!(
          message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
          status: "error_answer_guardrails",
          "#{guardrail_name}_status": :error,
          metrics: { guardrail_name => build_metrics(start_time, error) },
          llm_response: { guardrail_name => error.llm_response },
        )
      end
    end
  end
end
