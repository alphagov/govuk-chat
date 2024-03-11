FactoryBot.define do
  factory :question do
    conversation
    sequence(:message) { |n| "Message #{n}" }
  end
end
