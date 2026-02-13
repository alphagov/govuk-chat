FactoryBot.define do
  factory :question do
    conversation
    conversation_session_id { SecureRandom.uuid }
    sequence(:message) { |n| "Message #{n}" }
    answer_strategy { :claude_structured_answer }

    trait :with_answer do
      after(:build) do |question|
        build(:answer, question:)
      end
    end
  end
end
