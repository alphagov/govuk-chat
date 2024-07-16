module AnswerComposition
  module Pipeline
    class SearchResultFetcher
      delegate :question_message, to: :context

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        if search_results.blank?
          context.abort_pipeline!(
            message: Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE,
            status: "abort_no_govuk_content",
          )
        else
          context.search_results = search_results
        end
      end

    private

      attr_reader :context

      def search_results
        @search_results ||= Search::ResultsForQuestion.call(question_message).results
      end
    end
  end
end
