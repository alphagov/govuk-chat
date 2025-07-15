module AnswerComposition::Pipeline::OpenAI
  class QuestionRephraser
    OPENAI_MODEL = "gpt-4o-mini".freeze

    def self.call(...) = new(...).call

    def initialize(question_message, question_records)
      @question_message = question_message
      @question_records = question_records
    end

    def call
      AnswerComposition::Pipeline::QuestionRephraser::Result.new(
        llm_response: openai_response_choice,
        rephrased_question: openai_response_choice.dig("message", "content"),
        metrics:,
      )
    end

  private

    attr_reader :question_message, :question_records

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

    def user_prompt
      config[:user_prompt]
        .sub("{question}", question_message)
        .sub("{message_history}", message_history)
    end

    def openai_client
      @openai_client ||= OpenAIClient.build
    end

    def message_history
      question_records.flat_map(&method(:map_question)).join("\n")
    end

    def map_question(question)
      question_message = question.answer.rephrased_question || question.message

      [
        format_messsage("user", question_message),
        format_messsage("assistant", question.answer.message),
      ]
    end

    def config
      Rails.configuration.govuk_chat_private.llm_prompts.openai.question_rephraser
    end

    def format_messsage(actor, message)
      ["#{actor}:", '"""', message, '"""'].join("\n")
    end

    def metrics
      {
        llm_prompt_tokens: openai_response.dig("usage", "prompt_tokens"),
        llm_completion_tokens: openai_response.dig("usage", "completion_tokens"),
        llm_cached_tokens: openai_response.dig("usage", "prompt_tokens_details", "cached_tokens"),
        model: openai_response["model"],
      }
    end
  end
end
