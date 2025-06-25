ConversationQuestions = Data.define(:questions) do
  def to_json(*_args)
    to_h.to_json
  end
end
