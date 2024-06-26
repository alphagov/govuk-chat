class Answer < ApplicationRecord
  belongs_to :question
  has_many :sources, -> { order(relevancy: :asc) }, class_name: "AnswerSource"
  has_one :feedback, class_name: "AnswerFeedback"

  enum :status,
       {
         abort_forbidden_words: "abort_forbidden_words",
         abort_no_govuk_content: "abort_no_govuk_content",
         abort_timeout: "abort_timeout",
         error_answer_service_error: "error_answer_service_error",
         error_context_length_exceeded: "error_context_length_exceeded",
         error_non_specific: "error_non_specific",
         success: "success",
       },
       prefix: true
end
