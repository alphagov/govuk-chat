FactoryBot.define do
  factory :answer_source do
    answer
    sequence(:relevancy) { |n| n }
  end
end
