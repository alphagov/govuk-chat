FactoryBot.define do
  factory :conversation do
    trait :with_history do
      after :create do |conversation|
        [
          {
            question: "How do I pay my tax",
            answer: "What type of tax",
          },
          {
            question: "What types are there",
            answer: "Self-assessment, PAYE, Corporation tax",
          },
        ].each do |msg|
          answer = build :answer, message: msg[:answer]
          create :question, conversation:, answer:, message: msg[:question]
        end
        create :question, conversation:, message: "corporation tax"
      end
    end
  end
end
