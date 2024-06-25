FactoryBot.define do
  factory :answer_feedback do
    answer
    useful { [true, false].sample }
  end
end
