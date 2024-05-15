module Admin
  module QuestionsHelper
    def format_answer_status_as_tag(status, with_description_suffix: false)
      label, colour, description = case status
                                   when "success"
                                     %w[Success green]
                                   when "abort_forbidden_words"
                                     ["Abort", "orange", "forbidden words in question"]
                                   when "abort_no_govuk_content"
                                     ["Abort", "orange", "no GOV.UK content found"]
                                   when "error_answer_service_error"
                                     ["Error", "red", "received error from LLM"]
                                   when "error_context_length_exceeded"
                                     ["Error", "red", "too many tokens sent to LLM"]
                                   when "error_non_specific"
                                     ["Error", "red", "unexpected system error"]
                                   when nil
                                     %w[Pending yellow]
                                   else
                                     raise "Unknown status: #{status}"
                                   end

      tag_title = description ? "#{label} - #{description}" : label.to_s
      tag_el = tag.span(label, title: tag_title, class: "govuk-tag govuk-tag--#{colour}")

      if description && with_description_suffix
        safe_join([tag_el, " - #{description}"])
      else
        tag_el
      end
    end

    def question_show_summary_list_rows(question, answer)
      conversation = question.conversation
      search_text = question.answer&.rephrased_question || question.message
      rows = [
        {
          field: "Conversation id",
          value: link_to(conversation.id, admin_show_conversation_path(conversation), title: "View whole conversation", class: "govuk-link"),
        },
        {
          field: "Question number",
          value: "#{conversation.questions.find_index(question) + 1} of #{conversation.questions.count}",
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
                  value: format_answer_status_as_tag(nil, with_description_suffix: true),
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
