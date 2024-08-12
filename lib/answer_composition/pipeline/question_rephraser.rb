module AnswerComposition
  module Pipeline
    class QuestionRephraser
      OPENAI_MODEL = "gpt-3.5-turbo".freeze

      delegate :question, to: :context

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        return if first_question?

        context.question_message = openai_response.dig("choices", 0, "message", "content")
      rescue OpenAIClient::ContextLengthExceededError => e
        raise OpenAIClient::ContextLengthExceededError.new("Exceeded context length rephrasing #{question.message}", e.response)
      rescue OpenAIClient::RequestError => e
        raise OpenAIClient::RequestError.new("could not rephrase #{question.message}", e.response)
      end

    private

      attr_reader :context

      def openai_response
        openai_client.chat(
          parameters: {
            model: OPENAI_MODEL,
            messages:,
            temperature: 0.0,
          },
        )
      end

      def messages
        [
          { role: "system", content: config[:system_prompt] },
          { role: "user", content: user_prompt },
        ]
      end

      def message_records
        Question.where(conversation: question.conversation)
                .includes(:answer)
                .joins(:answer)
                .last(5)
      end

      def message_history
        message_records.flat_map(&method(:map_question)).join("\n")
      end

      def map_question(question)
        question_message = question.answer.rephrased_question || question.message

        [
          format_messsage("user", question_message),
          format_messsage("assistant", question.answer.message),
        ]
      end

      def first_question?
        question.conversation.questions.count < 2
      end

      def config
        Rails.configuration.llm_prompts.question_rephraser
      end

      def user_prompt
        config[:user_prompt]
          .sub("{question}", question.message)
          .sub("{message_history}", message_history)
      end

      def openai_client
        @openai_client ||= OpenAIClient.build
      end

      def format_messsage(actor, message)
        ["#{actor}:", '"""', message, '"""'].join("\n")
      end
    end
  end
end
