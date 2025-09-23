FactoryBot.define do
  factory :answer do
    question
    sequence(:message) { |n| "Answer #{n}" }
    status { :answered }
    completeness { :complete }
    sources { [] }
    feedback { nil }
    analysis { nil }

    trait :with_sources do
      sources do
        [
          build(:answer_source,
                relevancy: 0,
                chunk: build(:answer_source_chunk,
                             base_path: "/income-tax",
                             exact_path: "/income-tax")),
          build(:answer_source,
                relevancy: 1,
                chunk: build(:answer_source_chunk,
                             base_path: "/vat-tax",
                             exact_path: "/vat-tax")),
        ]
      end
    end

    trait :with_feedback do
      feedback { build(:answer_feedback) }
    end

    trait :with_analysis do
      analysis { build(:answer_analysis) }
    end
  end
end
