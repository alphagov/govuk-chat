module AnswerComposition
  module Pipeline
    class AnswerGuardrails < OutputGuardrails
      def call
        start_time = AnswerComposition.monotonic_time

        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::ANSWER_GUARDRAILS_FAILED_MESSAGE,
            status: "abort_answer_guardrails",
            answer_guardrails_failures: response.guardrails,
            answer_guardrails_status: :fail,
            metrics: { guardrail_name => build_metrics(start_time, response) },
          )
        else
          context.answer.assign_attributes(answer_guardrails_status: :pass)
          context.answer.assign_metrics(guardrail_name, build_metrics(start_time, response))
        end
      rescue ::Guardrails::MultipleChecker::ResponseError => e
        abort_after_response_error(e, start_time, Answer::CannedResponses::ANSWER_GUARDRAILS_FAILED_MESSAGE)
      end
    end
  end
end
