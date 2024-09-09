class Answer < ApplicationRecord
  module CannedResponses
    NO_CONTENT_FOUND_REPONSE = "Sorry, I can’t find anything on GOV.UK to help me answer your question. " \
      "Please try asking a different question.".freeze
    CONTEXT_LENGTH_EXCEEDED_RESPONSE = "Sorry, your last question was too complex for me to answer. " \
      "Could you make your question more specific? You can also try splitting it into multiple " \
      "smaller questions and asking them separately.".freeze
    OPENAI_CLIENT_ERROR_RESPONSE = <<~MESSAGE.freeze
      Sorry, something went wrong while trying to answer your question. Try again later.

      We saved your conversation. Check [GOV.UK guidance for businesses](https://www.gov.uk/browse/business) if you need information now.
    MESSAGE
    TIMED_OUT_RESPONSE = "Sorry, something went wrong and I could not find an answer in time. " \
      "Please try again.".freeze
    UNSUCCESSFUL_REQUEST_MESSAGE = <<~MESSAGE.freeze
      Sorry, something went wrong while trying to answer your question. Try again later.

      We saved your conversation. Check [GOV.UK guidance for businesses](https://www.gov.uk/browse/business) if you need information now.
    MESSAGE
    GUARDRAILS_FAILED_MESSAGE = <<~MESSAGE.freeze
      I generated an answer to your question, but it does not meet the GOV.UK Chat content guidelines. This might be because it contains unclear or misleading information, or offers advice about money or your personal circumstances.

      Please try asking about something else or rephrasing your question.
    MESSAGE
    LLM_CANNOT_ANSWER_MESSAGE = "Sorry, I cannot answer that question.".freeze
  end

  belongs_to :question
  has_many :sources, -> { order(relevancy: :asc) }, class_name: "AnswerSource"
  has_one :feedback, class_name: "AnswerFeedback"

  enum :status,
       {
         # TODO: remove this status from DB once we're confident this isn't coming back
         abort_forbidden_words: "abort_forbidden_words",
         abort_llm_cannot_answer: "abort_llm_cannot_answer",
         abort_no_govuk_content: "abort_no_govuk_content",
         abort_output_guardrails: "abort_output_guardrails",
         abort_question_routing: "abort_question_routing",
         abort_timeout: "abort_timeout",
         error_answer_service_error: "error_answer_service_error",
         error_context_length_exceeded: "error_context_length_exceeded",
         error_invalid_llm_response: "error_invalid_llm_response",
         error_output_guardrails: "error_output_guardrails",
         error_non_specific: "error_non_specific",
         error_question_routing: "error_question_routing",
         success: "success",
       },
       prefix: true

  enum :output_guardrail_status, { pass: "pass", fail: "fail", error: "error" }

  def build_sources_from_search_results(search_results)
    self.sources = search_results.map.with_index do |result, relevancy|
      sources.build(
        base_path: result.base_path,
        exact_path: result.exact_path,
        title: result.title,
        relevancy:,
        content_chunk_id: result._id,
        content_chunk_digest: result.digest,
        heading: result.heading_hierarchy.last,
      )
    end
  end

  def serialize_for_export
    as_json.merge("sources" => sources.map(&:serialize_for_export))
  end

  def assign_metrics(namespace, values)
    self.metrics ||= {}
    self.metrics[namespace] = values
  end
end
