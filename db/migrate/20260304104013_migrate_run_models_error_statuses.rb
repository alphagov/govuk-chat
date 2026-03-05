class MigrateRunModelsErrorStatuses < ActiveRecord::Migration[8.0]
  class AnswerAnalysis::AnswerRelevancyRun < ApplicationRecord; end
  class AnswerAnalysis::ContextRelevancyRun < ApplicationRecord; end
  class AnswerAnalysis::FaithfulnessRun < ApplicationRecord; end

  def up
    answer_relevancy_reasons = [
      "No statements were extracted from the answer.",
      "No verdicts were generated for the extracted statements.",
    ]
    answer_relevancy_reasons.each do |reason|
      AnswerAnalysis::ContextRelevancyRun.where(reason:).update_all(
        status: :error,
        score: nil,
        reason: nil,
        error_message: reason,
      )
    end

    faithfulness_reasons = [
      "No truths were extracted from the retrieval context.",
      "No claims were extracted from the answer.",
      "No verdicts were generated for the extracted claims.",
    ]
    faithfulness_reasons.each do |reason|
      AnswerAnalysis::FaithfulnessRun.where(reason:).update_all(
        status: :error,
        score: nil,
        reason: nil,
        error_message: reason,
      )
    end

    context_relevancy_reasons = [
      "No sources were retrieved when generating the answer.",
      "No information needs were generated.",
      "No truths were generated.",
      "No verdicts were generated.",
    ]
    context_relevancy_reasons.each do |reason|
      AnswerAnalysis::ContextRelevancyRun.where(reason:).update_all(
        status: :error,
        score: nil,
        reason: nil,
        error_message: reason,
      )
    end
  end

  def down
    answer_relevancy_error_messages = [
      "No statements were extracted from the answer.",
      "No verdicts were generated for the extracted statements.",
    ]
    answer_relevancy_error_messages.each do |error_message|
      AnswerAnalysis::ContextRelevancyRun.where(error_message: error_message).update_all(
        status: :success,
        reason: error_message,
        error_message: nil,
        score: 1.0,
      )

      faithfulness_error_messages = [
        "No truths were extracted from the retrieval context.",
        "No claims were extracted from the answer.",
        "No verdicts were generated for the extracted claims.",
      ]

      faithfulness_error_messages.each do |error_message|
        AnswerAnalysis::FaithfulnessRun.where(error_message: error_message).update_all(
          status: :success,
          reason: error_message,
          error_message: nil,
          score: 1.0,
        )
      end

      context_relevancy_error_messages = [
        "No sources were retrieved when generating the answer.",
        "No information needs were generated.",
        "No truths were generated.",
        "No verdicts were generated.",
      ]

      context_relevancy_error_messages.each do |error_message|
        AnswerAnalysis::ContextRelevancyRun.where(error_message: error_message).update_all(
          status: :success,
          reason: error_message,
          error_message: nil,
          score: 1.0,
        )
      end
    end
  end
end
