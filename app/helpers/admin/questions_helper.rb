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
          value: link_to(
            conversation.id,
            admin_questions_path(conversation_id: conversation.id),
            title: "View whole conversation",
            class: "govuk-link",
          ),
        },
        {
          field: "Conversation session id",
          value: link_to(
            question.conversation_session_id,
            admin_questions_path(conversation_session_id: question.conversation_session_id),
            title: "View all questions for this conversation session",
            class: "govuk-link",
          ),
        },
        (
          if conversation.end_user_id.present?
            {
              field: "End user ID",
              value: link_to(
                conversation.end_user_id,
                admin_questions_path(end_user_id: conversation.end_user_id),
                title: "View all questions for this end user",
                class: "govuk-link",
              ),
            }
          end
        ),
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
          value: escaped_simple_format(question.message),
        },
        (
          if question.unsanitised_message.present?
            {
              field: "Unsanitised question",
              value: "ASCII smuggling decoded:<br><br>".html_safe + decode_and_mark_unicode_tag_segments(question.unsanitised_message),
            }
          end
        ),
        {
          field: "Show search results",
          value: link_to(search_text, admin_search_path(params: { search_text: }), class: "govuk-link"),
        },
      ].compact

      signon_user = conversation.signon_user
      if signon_user.present?
        rows << {
          field: "Signon user",
          value: safe_join([
            signon_user.name,
            " (",
            link_to("View all questions", admin_questions_path(signon_user_id: signon_user.id), class: "govuk-link"),
            ")",
          ]),
        }
      end

      rows << {
        field: "Source",
        value: conversation.source_api? ? "API" : conversation.source.humanize,
      }

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
                  {
                    field: "Answer strategy",
                    value: question.answer_strategy.humanize,
                  },
                  {
                    field: "Completeness",
                    value: answer.completeness&.humanize,
                  },
                  {
                    field: "Jailbreak guardrails status",
                    value: answer.jailbreak_guardrails_status,
                  },
                  {
                    field: "Question routing label",
                    value: Rails.configuration.question_routing_labels.dig(answer.question_routing_label, :label),
                  },
                  {
                    field: "Question routing confidence score",
                    value: answer.question_routing_confidence_score,
                  },
                  {
                    field: "Question routing guardrails status",
                    value: answer.question_routing_guardrails_status,
                  },
                  {
                    field: "Question routing guardrails triggered",
                    value: answer.question_routing_guardrails_failures.join(", "),
                  },
                  {
                    field: "Answer guardrails status",
                    value: answer.answer_guardrails_status,
                  },
                  {
                    field: "Answer guardrails triggered",
                    value: answer.answer_guardrails_failures.join(", "),
                  },
                  {
                    field: "Forbidden terms detected",
                    value: answer.forbidden_terms_detected.map { |term| "\"#{term}\"" }.to_sentence,
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
        used_source_links = answer.sources.used.map do |source|
          tag.a(source.title, href: source.govuk_url, class: "govuk-link")
        end

        unused_source_links = answer.sources.unused.map do |source|
          tag.a(source.title, href: source.govuk_url, class: "govuk-link")
        end

        rows << {
          field: "Used sources",
          value: safe_join(used_source_links, tag.br),
        }

        if unused_source_links.present?
          rows << {
            field: "Unused sources",
            value: safe_join(unused_source_links, tag.br),
          }
        end
      end

      if answer&.feedback.present?
        feedback = answer.feedback

        rows << [
          {
            field: "Feedback created at",
            value: feedback.created_at.to_fs(:time_and_date),
          },
          {
            field: "Feedback",
            value: feedback.useful == true ? "Useful" : "Not useful",
          },
        ]
      end

      rows.flatten
    end

    def decode_and_mark_unicode_tag_segments(input)
      input_segments = input.scan(UnicodeTags::SCAN_REGEX)

      marked_segments = input_segments.map do |segment|
        if segment.match?(UnicodeTags::MATCH_REGEX)
          tag.mark(decode_unicode_tags(segment))
        else
          segment
        end
      end

      safe_join(marked_segments)
    end

    def decode_unicode_tags(string)
      decoded_chars = string.chars.map do |char|
        codepoint = char.ord
        if codepoint.between?(UnicodeTags::RANGE_START, UnicodeTags::RANGE_END)
          (codepoint - UnicodeTags::DECODE_SUBTRACT).chr(Encoding::UTF_8)
        else
          char
        end
      end
      decoded_chars.join
    end
  end
end
