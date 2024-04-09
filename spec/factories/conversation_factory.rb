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
          question = create :question, conversation:, message: msg[:question]
          create :answer, question:, message: msg[:answer]
        end
        create :question, conversation:, message: "corporation tax"
      end
    end
  end
end
