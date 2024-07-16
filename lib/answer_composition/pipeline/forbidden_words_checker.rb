module AnswerComposition
  module Pipeline
    class ForbiddenWordsChecker
      delegate :question_message, to: :context

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        words = question_message.downcase.split(/\b/)
        forbidden_words = Rails.configuration.question_forbidden_words

        if forbidden_words.intersection(words).any?
          context.abort_pipeline!(
            message: Answer::CannedResponses::FORBIDDEN_WORDS_RESPONSE,
            status: "abort_forbidden_words",
          )
        end
      end

    private

      attr_reader :context
    end
  end
end
