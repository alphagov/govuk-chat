class Answer < ApplicationRecord
  module CannedResponses
    FORBIDDEN_WORDS_RESPONSE = "Sorry, I cannot answer that. Ask me a question about " \
      "business or trade and I'll use GOV.UK guidance to answer it.".freeze
    NO_CONTENT_FOUND_REPONSE = "Sorry, I can’t find anything on GOV.UK to help me answer your question. " \
      "Please try asking a different question.".freeze
    OPENAI_CLIENT_ERROR_RESPONSE = <<~MESSAGE.freeze
      Sorry, there is a problem with OpenAI's API. Try again later.

      We saved your conversation.

      Check [GOV.UK guidance for businesses](https://www.gov.uk/browse/business) if you need information now.
    MESSAGE
    TIMED_OUT_RESPONSE = "Sorry, something went wrong and I could not find an answer in time. " \
      "Please try again.".freeze
    UNSUCCESSFUL_REQUEST_MESSAGE = "There's been a problem retrieving a response to your question.".freeze
    GUARDRAILS_FAILED_MESSAGE = <<~MESSAGE.freeze
      Sorry, the answer does not meet the GOV.UK Chat content guidelines.
      This might be because it contains unclear, misleading or inappropriate information.

      Please try asking about something else or rephrasing your question.
    MESSAGE
  end

  belongs_to :question
  has_many :sources, -> { order(relevancy: :asc) }, class_name: "AnswerSource"
  has_one :feedback, class_name: "AnswerFeedback"

  enum :status,
       {
         abort_forbidden_words: "abort_forbidden_words",
         abort_no_govuk_content: "abort_no_govuk_content",
         abort_output_guardrails: "abort_output_guardrails",
         abort_timeout: "abort_timeout",
         error_answer_service_error: "error_answer_service_error",
         error_context_length_exceeded: "error_context_length_exceeded",
         error_output_guardrails: "error_output_guardrails",
         error_non_specific: "error_non_specific",
         success: "success",
       },
       prefix: true

  enum :output_guardrail_status, { pass: "pass", fail: "fail", error: "error" }

  def build_sources_from_search_results(search_results)
    self.sources = search_results.map.with_index do |result, relevancy|
      sources.build(
        exact_path: result.url,
        base_path: result.base_path,
        title: result.title,
        relevancy:,
        content_chunk_id: result._id,
        content_chunk_digest: result.digest,
        heading: result.heading_hierarchy.last,
      )
    end
  end
end
