module AnswerAnalysis
  class AnswerRelevancyAggregate < ApplicationRecord
    include AnalysisResultsCreatable

    belongs_to :answer
    has_many :runs, class_name: "AnswerAnalysis::AnswerRelevancyRun"
  end
end
