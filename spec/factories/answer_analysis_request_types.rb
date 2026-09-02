FactoryBot.define do
  factory :answer_analysis_request_types, class: "AnswerAnalysis::RequestTypes" do
    answer
    primary_request_type { "factual_lookup" }
    secondary_request_type { "do_task" }
    confidence { 0.9 }
    reasoning { "The user is asking for a specific figure." }
  end
end
