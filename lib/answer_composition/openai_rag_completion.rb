module AnswerComposition
  class OpenaiRagCompletion
    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
      @retriever = Retrieval::SearchApiV1Retriever
      @openai_client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"))
    end

    def call
      message = openai_response.dig("choices", 0, "message", "content")
      question.build_answer(message:, status: "success")
    end

  private

    attr_reader :question, :retriever, :openai_client

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
        { role: "user", content: question.message },
      ]
    end

    def system_prompt
      <<~PROMPT
        #{Prompts::GOVUK_DESIGNER}

        Context:
        #{context(question)}

      PROMPT
    end

    def context(query)
      retriever.call(query:).join("\n")
    end
  end
end
