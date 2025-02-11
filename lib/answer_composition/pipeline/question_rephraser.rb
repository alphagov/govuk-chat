module AnswerComposition
  module Pipeline
    class QuestionRephraser
      Result = Data.define(:llm_response, :rephrased_question, :metrics)

      def initialize(llm_provider:)
        @llm_provider = llm_provider
      end

      def call(context)
        records = message_records(context.question.conversation)

        return if records.blank? # First question in a conversation

        start_time = Clock.monotonic_time
        klass = case llm_provider
                when :openai
                  Pipeline::OpenAI::QuestionRephraser
                when :claude
                  Pipeline::Claude::QuestionRephraser
                else
                  raise "Unknown llm provider: #{llm_provider}"
                end

        result = klass.call(context.question.message, records)

        context.answer.assign_llm_response("question_rephrasing", result.llm_response)
        context.question_message = result.rephrased_question
        context.answer.assign_metrics(
          "question_rephrasing",
          { duration: Clock.monotonic_time - start_time }.merge(result.metrics),
        )
      end

    private

      attr_reader :llm_provider

      def message_records(conversation)
        @message_records ||= Question.where(conversation:)
                                     .includes(:answer)
                                     .joins(:answer)
                                     .last(5)
                                     .select(&:use_in_rephrasing?)
      end
    end
  end
end
