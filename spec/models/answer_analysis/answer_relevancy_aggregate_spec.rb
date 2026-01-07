RSpec.describe AnswerAnalysis::AnswerRelevancyAggregate do
  include_examples "auto_evaluation results creatable",
                   :answer_relevancy_aggregate,
                   AnswerAnalysis::AnswerRelevancyRun
end
