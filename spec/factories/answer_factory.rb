FactoryBot.define do
  factory :answer do
    question
    sequence(:message) { |n| "Answer #{n}" }
  end
end
