class BackfillNilvaluesForLlmResponsesAndMetrics < ActiveRecord::Migration[8.0]
  class AnswerAnalysisAnswerRelevancyRun < ApplicationRecord; end
  class AnswerAnalysisCoherenceRun < ApplicationRecord; end
  class AnswerAnalysisContextRelevancyRun < ApplicationRecord; end
  class AnswerAnalysisFaithfulnessRun < ApplicationRecord; end
  class AnswerAnalysisTopics < ApplicationRecord; end

  MODELS = [
    AnswerAnalysisAnswerRelevancyRun,
    AnswerAnalysisCoherenceRun,
    AnswerAnalysisContextRelevancyRun,
    AnswerAnalysisFaithfulnessRun,
    AnswerAnalysisTopics,
    Answer,
  ].freeze

  def up
    MODELS.each do |model|
      model.where(metrics: nil).update_all(metrics: {})
      model.where(llm_responses: nil).update_all(llm_responses: {})
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
