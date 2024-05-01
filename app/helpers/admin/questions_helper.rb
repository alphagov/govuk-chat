module Admin
  module QuestionsHelper
    def format_answer_status_as_tag(status)
      case status
      when "success"
        tag.span("Success", class: "govuk-tag govuk-tag--green")
      when "abort_forbidden_words", "abort_no_govuk_content"
        tag.span("Abort", class: "govuk-tag govuk-tag--orange")
      when "error_answer_service_error", "error_context_length_exceeded", "error_non_specific"
        tag.span("Error", class: "govuk-tag govuk-tag--red")
      when nil
        tag.span("Pending", class: "govuk-tag govuk-tag--yellow")
      else
        raise "Unknown status: #{status}"
      end
    end
  end
end
