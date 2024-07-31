FactoryBot.define do
  factory :question do
    conversation
    sequence(:message) { |n| "Message #{n}" }
    answer_strategy { :openai_structured_answer }

    trait :with_answer do
      after(:build) do |question|
        build(:answer, question:)
      end
    end
  end
end
