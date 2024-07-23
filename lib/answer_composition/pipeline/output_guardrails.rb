module AnswerComposition
  module Pipeline
    class OutputGuardrails
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        response = ::OutputGuardrails::FewShot.call(context.answer.message)
        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
            status: "abort_output_guardrails",
            output_guardrail_llm_response: response.llm_response,
            output_guardrail_failures: response.guardrails,
            output_guardrail_status: :fail,
          )
        else
          context.answer.assign_attributes(
            output_guardrail_status: :pass,
            output_guardrail_llm_response: response.llm_response,
          )
        end
      rescue ::OutputGuardrails::FewShot::ResponseError => e
        context.abort_pipeline!(
          message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
          status: "error_output_guardrails",
          output_guardrail_llm_response: e.llm_response,
          output_guardrail_status: :error,
        )
      end

    private

      attr_reader :context

      delegate :question_message, to: :context
    end
  end
end
