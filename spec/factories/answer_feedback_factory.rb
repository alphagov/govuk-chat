FactoryBot.define do
  factory :answer_feedback do
    answer
    useful { true }
  end
end
