module AnswerComposition
  module Pipeline
    class QuestionRoutingGuardrails
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        return if context.answer.question_routing_label == "genuine_rag"

        start_time = AnswerComposition.monotonic_time

        response = ::OutputGuardrails::FewShot.call(
          context.answer.message,
          :question_routing_guardrails,
        )
        context.answer.assign_llm_response("question_routing_guardrails", response.llm_response)

        if response.triggered
          context.answer.assign_attributes(
            message: Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE,
            status: "abort_output_guardrails",
            question_routing_guardrails_failures: response.guardrails,
          )
        end

        context.abort_pipeline(
          question_routing_guardrails_status: response.triggered ? :fail : :pass,
          metrics: { "question_routing_guardrails" => build_metrics(start_time, response) },
        )
      rescue ::OutputGuardrails::FewShot::ResponseError => e
        context.abort_pipeline!(
          message: Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE,
          status: "error_output_guardrails",
          question_routing_guardrail_status: :error,
          metrics: { "question_routing_guardrails" => build_metrics(start_time, e) },
          llm_response: { "question_routing_guardrails" => e.llm_response },
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
