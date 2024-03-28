FactoryBot.define do
  factory :answer do
    question
    sequence(:message) { |n| "Answer #{n}" }

    trait :with_sources do
      sources do
        [
          build(:answer_source, url: "https://example.com", relevancy: 0),
          build(:answer_source, url: "https://example.org", relevancy: 1),
        ]
      end
    end
  end
end
