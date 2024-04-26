FactoryBot.define do
  factory :answer do
    question
    sequence(:message) { |n| "Answer #{n}" }
    status { :success }

    trait :with_sources do
      sources do
        [
          build(:answer_source, url: "/income-tax", relevancy: 0),
          build(:answer_source, url: "/vat-tax", relevancy: 1),
        ]
      end
    end
  end
end
