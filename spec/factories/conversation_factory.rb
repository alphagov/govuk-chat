FactoryBot.define do
  factory :conversation do
    trait :with_history do
      after(:create) do |conversation|
        { "Hello" => "How can I help?", "Pay my tax" => "Which type of tax?" }.each do |q, a|
          question = create(:question, conversation:, message: q)
          create(:answer, question:, message: a)
        end
        create(:question, conversation:, message: "self assessment")
      end
    end
  end
end
