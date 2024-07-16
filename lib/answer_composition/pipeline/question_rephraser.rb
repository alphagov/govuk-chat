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

      attr_reader :context,

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
          { role: "system", content: system_prompt },
        ] + message_history
      end

      def message_history
        Question.where(conversation: question.conversation)
                .includes(:answer)
                .last(5)
                .flat_map(&method(:map_question))
      end

      def map_question(question)
        return [{ role: "user", content: question.message }] if question.answer.nil?

        [
          { role: "user", content: question.message },
          { role: "assistant", content: question.answer.message },
        ]
      end

      def first_question?
        question.conversation.questions.count < 2
      end

      def system_prompt
        Rails.configuration.llm_prompts.answer_composition.rephrase_question.system_prompt
      end

      def openai_client
        @openai_client ||= OpenAIClient.build
      end
    end
  end
end
