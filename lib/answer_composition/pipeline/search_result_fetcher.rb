module AnswerComposition
  module Pipeline
    class SearchResultFetcher
      delegate :question_message, to: :context

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = Clock.monotonic_time

        if search_results.blank?
          context.abort_pipeline!(
            message: Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE,
            status: "unanswerable_no_govuk_content",
            metrics: { "search_results" => build_metrics(start_time) },
          )
        else
          context.search_results = search_results

          context.answer.assign_metrics("search_results", build_metrics(start_time))
        end
      end

    private

      attr_reader :context

      def results_for_question
        @results_for_question ||= Search::ResultsForQuestion.call(question_message)
      end

      def search_results
        @search_results ||= results_for_question.results
      end

      def build_metrics(start_time)
        { duration: Clock.monotonic_time - start_time }.merge(results_for_question.metrics)
      end
    end
  end
end
