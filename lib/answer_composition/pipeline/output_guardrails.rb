module AnswerComposition
  module Pipeline
    class OutputGuardrails
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = context.current_time

        response = ::OutputGuardrails::FewShot.call(context.answer.message)
        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
            status: "abort_output_guardrails",
            output_guardrail_llm_response: response.llm_response,
            output_guardrail_failures: response.guardrails,
            output_guardrail_status: :fail,
            metrics: { "output_guardrails" => build_metrics(start_time, response) },
          )
        else
          context.answer.assign_attributes(
            output_guardrail_status: :pass,
            output_guardrail_llm_response: response.llm_response,
          )

          context.answer.assign_metrics("output_guardrails", build_metrics(start_time, response))
        end
      rescue ::OutputGuardrails::FewShot::ResponseError => e
        context.abort_pipeline!(
          message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
          status: "error_output_guardrails",
          output_guardrail_llm_response: e.llm_response,
          output_guardrail_status: :error,
          metrics: { "output_guardrails" => build_metrics(start_time, e) },
        )
      end

    private

      attr_reader :context

      def build_metrics(start_time, response_or_error)
        {
          duration: context.current_time - start_time,
          llm_prompt_tokens: response_or_error.llm_token_usage["prompt_tokens"],
          llm_completion_tokens: response_or_error.llm_token_usage["completion_tokens"],
        }
      end
    end
  end
end
