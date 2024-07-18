FactoryBot.define do
  factory :answer_pipeline_context, class: "AnswerComposition::Pipeline::Context" do
    skip_create
    question { build(:question) }
    initialize_with { new(question) }
  end
end
