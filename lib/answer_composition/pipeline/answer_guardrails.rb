module AnswerComposition
  module Pipeline
    class AnswerGuardrails < OutputGuardrails
      def call(context)
        start_time = Clock.monotonic_time
        response = generate_response(context)

        if response.triggered
          context.abort_pipeline!(
            message: Answer::CannedResponses::ANSWER_GUARDRAILS_FAILED_MESSAGE,
            status: "guardrails_answer",
            answer_guardrails_failures: response.triggered_guardrails,
            answer_guardrails_status: :fail,
            metrics: { guardrail_name => build_metrics(start_time, response) },
          )
        else
          context.answer.assign_attributes(answer_guardrails_status: :pass)
          context.answer.assign_metrics(guardrail_name, build_metrics(start_time, response))
        end
      rescue ::Guardrails::MultipleChecker::ResponseError => e
        abort_after_response_error(context, e, start_time, Answer::CannedResponses::ANSWER_GUARDRAILS_FAILED_MESSAGE)
      end
    end
  end
end
