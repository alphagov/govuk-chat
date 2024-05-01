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

    def question_show_summary_list_rows(question, answer)
      rows = [
        {
          field: "Question id",
          value: question.id,
        },
        {
          field: "Question created at",
          value: question.created_at.to_fs(:time_and_date),
        },
        {
          field: "Question",
          value: question.message,
        },
      ]

      if answer.present?
        rows << {
          field: "Rephrased question",
          value: answer&.rephrased_question,
        }
      end

      rows << {
        field: "Status",
        value: format_answer_status_as_tag(answer&.status),
      }

      if answer.present?
        rows << [
          {
            field: "Answer created at",
            value: answer.created_at.to_fs(:time_and_date),
          },
          {
            field: "Answer",
            value: render_answer_message(answer.message) +
              (render "govuk_publishing_components/components/details", {
                title: "Raw response",
              } do
                 render("components/code_snippet", content: answer.message)
               end
              ),
          },
        ]
      end

      if answer&.error_message.present?
        rows << {
          field: "Error message",
          value: render("components/code_snippet", content: answer.error_message),

        }
      end

      if answer&.sources.present?
        source_links = answer.sources.map do |source|
          url = "#{Plek.website_root}#{source.url}"
          tag.a(url, href: url, class: "govuk-link")
        end

        rows << {
          field: "Sources",
          value: safe_join(source_links, tag.br),
        }
      end

      rows.flatten
    end
  end
end
