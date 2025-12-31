RSpec.describe AnswerAnalysis::AnswerRelevancyAggregate do
  include_examples "analysis results creatable",
                   :answer_relevancy_aggregate,
                   AnswerAnalysis::AnswerRelevancyRun,
                   AutoEvaluation::AnswerRelevancy::Result
end
