class Answer < ApplicationRecord
  module CannedResponses
    FORBIDDEN_WORDS_RESPONSE = "Sorry, I cannot answer that. Ask me a question about " \
      "business or trade and I'll use GOV.UK guidance to answer it.".freeze
    NO_CONTENT_FOUND_REPONSE = "Sorry, I can't find anything on GOV.UK to help me answer your question. " \
      "Could you rewrite it so I can try answering again?".freeze
    CONTEXT_LENGTH_EXCEEDED_RESPONSE = "Sorry, I can't answer that in one go. Could you make your question " \
      "simpler or more specific, or ask each part separately?".freeze
    OPENAI_CLIENT_ERROR_RESPONSE = <<~MESSAGE.freeze
      Sorry, there is a problem with OpenAI's API. Try again later.

      We saved your conversation.

      Check [GOV.UK guidance for businesses](https://www.gov.uk/browse/business) if you need information now.
    MESSAGE
    TIMED_OUT_RESPONSE = "Sorry, something went wrong and I could not find an answer in time. " \
      "Please try again.".freeze
    UNSUCCESSFUL_REQUEST_MESSAGE = "There's been a problem retrieving a response to your question.".freeze
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
         error_non_specific: "error_non_specific",
         success: "success",
       },
       prefix: true

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
