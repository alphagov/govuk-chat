FactoryBot.define do
  factory :answer_source do
    answer
    sequence(:relevancy) { |n| n }
    sequence(:path) { |n| "/path/#{n}" }
    sequence(:title) { |n| "Title #{n}" }
  end
end
