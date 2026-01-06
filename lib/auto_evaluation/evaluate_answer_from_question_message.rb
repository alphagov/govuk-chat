module AutoEvaluation
  class EvaluateAnswerFromQuestionMessage
    class TaskFailedError < StandardError; end

    def self.call(...) = new(...).call

    def initialize(evaluation_class:, question_message:)
      @evaluation_class = evaluation_class
      @question_message = question_message
    end

    def call
      question = Question.new(message: question_message, conversation: Conversation.new)
      answer = AnswerComposition::PipelineRunner.call(question:, pipeline: [
        AnswerComposition::Pipeline::SearchResultFetcher,
        AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
      ])

      if answer.status =~ /^error/
        error_message = "Answer has an error status: #{answer.status} " \
                        "and error message: #{answer.error_message}"
        raise TaskFailedError, error_message
      end

      evaluation_class.call(answer)
    end

  private

    attr_reader :evaluation_class, :question_message
  end
end
