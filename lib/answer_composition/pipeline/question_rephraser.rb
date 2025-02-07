module AnswerComposition
  module Pipeline
    class QuestionRephraser
      OPENAI_MODEL = "gpt-4o-mini".freeze

      delegate :question, to: :context

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        return if first_question?

        start_time = Clock.monotonic_time

        context.question_message = openai_response_choice.dig("message", "content")

        context.answer.assign_llm_response("question_rephrasing", openai_response_choice)

        context.answer.assign_metrics("question_rephrasing", {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: openai_response.dig("usage", "prompt_tokens"),
          llm_completion_tokens: openai_response.dig("usage", "completion_tokens"),
          llm_cached_tokens: openai_response.dig("usage", "prompt_tokens_details", "cached_tokens"),
        })
      end

    private

      attr_reader :context

      def openai_response
        @openai_response ||= openai_client.chat(
          parameters: {
            model: OPENAI_MODEL,
            messages:,
            temperature: 0.0,
          },
        )
      end

      def openai_response_choice
        @openai_response_choice ||= openai_response.dig("choices", 0)
      end

      def messages
        [
          { role: "system", content: config[:system_prompt] },
          { role: "user", content: user_prompt },
        ]
      end

      def message_records
        @message_records ||= Question.where(conversation: question.conversation)
                                     .includes(:answer)
                                     .joins(:answer)
                                     .last(5)
                                     .select(&:use_in_rephrasing?)
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
        message_records.blank?
      end

      def config
        Rails.configuration.govuk_chat_private.llm_prompts.openai.question_rephraser
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
