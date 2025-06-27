ConversationQuestions = Data.define(
  :questions,
  :earlier_questions_url,
  :later_questions_url,
) do
  def initialize(questions: [], earlier_questions_url: nil, later_questions_url: nil)
    super
  end

  def to_json(*_args)
    to_h.compact.to_json
  end
end
