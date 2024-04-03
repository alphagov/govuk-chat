FactoryBot.define do
  factory :question do
    conversation
    sequence(:message) { |n| "Message #{n}" }
    answer_strategy { :open_ai_rag_completion }

    trait :with_answer do
      after(:build) do |question|
        build(:answer, question:)
      end
    end
  end
end
