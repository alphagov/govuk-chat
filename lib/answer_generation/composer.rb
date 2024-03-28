module AnswerGeneration
  class Composer
    delegate :answer_strategy, to: :question

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      case answer_strategy
      when "open_ai_rag_completion"
        OpenaiRagCompletion.call(question)
      when "govuk_chat_api"
        GovukChatApi.call(question)
      else
        raise "Answer strategy #{answer_strategy} not configured"
      end
    end

  private

    attr_reader :question
  end
end
