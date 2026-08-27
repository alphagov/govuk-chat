FactoryBot.define do
  factory :answer_feedback do
    answer
    reaction { :positive }
  end
end
