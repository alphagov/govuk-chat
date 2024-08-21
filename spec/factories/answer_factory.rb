FactoryBot.define do
  factory :answer do
    question
    sequence(:message) { |n| "Answer #{n}" }
    status { :success }
    sources { [] }

    trait :with_sources do
      sources do
        [
          build(:answer_source, exact_path: "/income-tax", relevancy: 0),
          build(:answer_source, exact_path: "/vat-tax", relevancy: 1),
        ]
      end
    end

    trait :with_feedback do
      feedback { build(:answer_feedback) }
    end
  end
end
