class Answer < ApplicationRecord
  belongs_to :question
  has_many :sources, -> { order(relevancy: :asc) }, class_name: "AnswerSource"

  enum :status,
       {
         success: "success",
         error_non_specific: "error_non_specific",
         error_answer_service_error: "error_answer_service_error",
         abort_forbidden_words: "abort_forbidden_words",
         error_context_length_exceeded: "error_context_length_exceeded",
       },
       prefix: true
end
