class AddQuestionRoutingStatusEnum < ActiveRecord::Migration[7.1]
  def change
    create_enum "question_routing_label", %w[
      about_mps
      advice_opinions_predictions
      character_fun
      content_not_govuk
      genuine_rag
      gov_transparency
      greetings
      harmful_vulgar_controversy
      multi_questions
      negative_acknowledgement
      non_english
      personal_info
      positive_acknowledgement
      vague_acronym_grammar
    ]
  end
end
