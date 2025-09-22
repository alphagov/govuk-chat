FactoryBot.define do
  factory :answer_source do
    answer
    chunk(factory: :answer_source_chunk)
    sequence(:relevancy) { |n| n }
    search_score { rand(0.1..1.0) }
    weighted_score { rand(0.1..2.0) }
  end
end
