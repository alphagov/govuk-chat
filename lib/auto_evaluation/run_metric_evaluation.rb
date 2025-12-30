module AutoEvaluation
  class RunMetricEvaluation
    def self.call(...) = new(...).call

    def initialize(metric_class:, question_message:)
      @metric_class = metric_class
      @question_message = question_message
    end

    def call
      question = Question.new(message: question_message, conversation: Conversation.new)
      answer = AnswerComposition::PipelineRunner.call(question:, pipeline: [
        AnswerComposition::Pipeline::SearchResultFetcher,
        AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
      ])

      return answer if answer.status =~ /^error/

      metric_class.call(
        question_message:,
        answer_message: answer.message,
      )
    end

  private

    attr_reader :metric_class, :question_message
  end
end
