module AnswerComposition
  module Pipeline
    class OutputGuardrails
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = AnswerComposition.monotonic_time

        response = ::OutputGuardrails::FewShot.call(context.answer.message)
        context.answer.assign_llm_response("output_guardrails", response.llm_response)

        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
            status: "abort_answer_guardrails",
            answer_guardrails_failures: response.guardrails,
            answer_guardrails_status: :fail,
            metrics: { "output_guardrails" => build_metrics(start_time, response) },
          )
        else
          context.answer.assign_attributes(answer_guardrails_status: :pass)
          context.answer.assign_metrics("output_guardrails", build_metrics(start_time, response))
        end
      rescue ::OutputGuardrails::FewShot::ResponseError => e
        context.abort_pipeline!(
          message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
          status: "error_answer_guardrails",
          answer_guardrails_status: :error,
          metrics: { "output_guardrails" => build_metrics(start_time, e) },
          llm_response: { "output_guardrails" => e.llm_response },
        )
      end

    private

      attr_reader :context

      def build_metrics(start_time, response_or_error)
        {
          duration: AnswerComposition.monotonic_time - start_time,
          llm_prompt_tokens: response_or_error.llm_token_usage["prompt_tokens"],
          llm_completion_tokens: response_or_error.llm_token_usage["completion_tokens"],
        }
      end
    end
  end
end
