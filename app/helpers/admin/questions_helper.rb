module Admin
  module QuestionsHelper
    def format_answer_status_as_tag(status, with_description_suffix: false)
      statuses = Rails.configuration.answer_statuses
      raise "Unknown status: #{status}" unless statuses.key?(status)

      label = statuses[status].label
      colour = statuses[status].label_colour
      description = statuses[status].description

      tag_title = description ? "#{label} - #{description}" : label.to_s
      tag_el = tag.span(label, title: tag_title, class: "govuk-tag govuk-tag--#{colour}")

      if description && with_description_suffix
        safe_join([tag_el, " - #{description}"])
      else
        tag_el
      end
    end

    def question_show_summary_list_rows(question, answer, question_number, total_questions)
      conversation = question.conversation
      search_text = question.answer&.rephrased_question || question.message
      rows = [
        {
          field: "Conversation id",
          value: link_to(conversation.id, admin_show_conversation_path(conversation), title: "View whole conversation", class: "govuk-link"),
        },
        {
          field: "Question number",
          value: "#{question_number} of #{total_questions}",
        },
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
        {
          field: "Show search results",
          value: link_to(search_text, admin_search_path(params: { search_text: }), class: "govuk-link"),
        },
      ]

      rows << if answer.present?
                [
                  {
                    field: "Rephrased question",
                    value: answer&.rephrased_question,
                  },
                  {
                    field: "Status",
                    value: format_answer_status_as_tag(answer.status, with_description_suffix: true),
                  },
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
              else
                {
                  field: "Status",
                  value: format_answer_status_as_tag(question.answer_status, with_description_suffix: true),
                }
              end

      if answer&.error_message.present?
        rows << {
          field: "Error message",
          value: render("components/code_snippet", content: answer.error_message),

        }
      end

      if answer&.sources.present?
        source_links = answer.sources.map do |source|
          tag.a(source.title, href: source.url, class: "govuk-link")
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
