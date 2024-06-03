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

    trait :expired do
      after :create do |conversation|
        conversation.questions.destroy_all
        max_question_age_days = Rails.configuration.conversations.max_question_age_days
        create(:question,
               :with_answer,
               conversation:,
               created_at: (max_question_age_days + 1).days.ago)
      end
    end

    trait :not_expired do
      after :create do |conversation|
        conversation.questions.destroy_all
        create(:question, :with_answer, conversation:)
      end
    end
  end
end
