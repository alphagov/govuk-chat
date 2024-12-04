class BackfillOldAnswerStatuses < ActiveRecord::Migration[8.0]
  class Answer < ApplicationRecord; end

  def up
    simple_mappings = {
      abort_answer_guardrails: :guardrails_answer,
      abort_forbidden_terms: :guardrails_forbidden_terms,
      abort_jailbreak_guardrails: :guardrails_jailbreak,
      abort_llm_cannot_answer: :unanswerable_llm_cannot_answer,
      abort_no_govuk_content: :unanswerable_no_govuk_content,
      abort_question_routing_guardrails: :guardrails_question_routing,
      abort_user_shadow_banned: :banned,
      success: :answered,
    }

    simple_mappings.each do |old_status, new_status|
      Answer.where(status: old_status).update_all(status: new_status)
    end

    question_routing_mappings = {
      clarification: %w[
        greetings
        multi_questions
        vague_acronym_grammar
      ],
      unanswerable_question_routing: %w[
        about_mps
        advice_opinions_predictions
        character_fun
        gov_transparency
        harmful_vulgar_controversy
        negative_acknowledgement
        non_english
        personal_info
        positive_acknowledgement
      ],

    }

    question_routing_mappings.each do |new_status, question_routing_labels|
      Answer
        .where(status: %w[abort_question_routing abort_question_routing_token_limit],
               question_routing_label: question_routing_labels)
        .update_all(status: new_status)
    end
  end
end
