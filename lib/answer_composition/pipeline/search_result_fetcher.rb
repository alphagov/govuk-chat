module AnswerComposition
  module Pipeline
    class SearchResultFetcher
      delegate :question_message, to: :context

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = context.current_time

        if search_results.blank?
          context.abort_pipeline!(
            message: Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE,
            status: "abort_no_govuk_content",
            metrics: { "search_results" => build_metrics(start_time) },
          )
        else
          context.search_results = search_results

          context.answer.assign_metrics("search_results", build_metrics(start_time))
        end
      end

    private

      attr_reader :context

      def search_results
        @search_results ||= Search::ResultsForQuestion.call(question_message).results
      end

      def build_metrics(start_time)
        { duration: context.current_time - start_time }
      end
    end
  end
end
