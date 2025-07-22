class AnswerTopic::Tagger
  def self.call(answer)
    answer_strategy = answer.question.answer_strategy.to_sym

    case answer_strategy
    when :claude_structured_answer
      AnswerTopic::Claude::Tagger.call(answer)
    else
      raise "Invalid strategy: #{answer_strategy}"
    end
  end
end
