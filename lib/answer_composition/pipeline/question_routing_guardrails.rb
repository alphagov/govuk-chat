module AnswerComposition
  module Pipeline
    class QuestionRoutingGuardrails < OutputGuardrails
      def call(context)
        return if context.answer.question_routing_label == "genuine_rag"

        start_time = Clock.monotonic_time
        response = generate_response(context)

        if response.triggered
          context.answer.assign_attributes(
            message: Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE,
            status: "guardrails_question_routing",
            question_routing_guardrails_failures: response.guardrails,
          )
        end

        context.abort_pipeline(
          question_routing_guardrails_status: response.triggered ? :fail : :pass,
          metrics: { guardrail_name => build_metrics(start_time, response) },
        )
      rescue ::Guardrails::MultipleChecker::ResponseError => e
        abort_after_response_error(context, e, start_time, Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE)
      end
    end
  end
end
