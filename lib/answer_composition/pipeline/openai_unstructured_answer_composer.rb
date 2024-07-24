module AnswerComposition::Pipeline
  class OpenAIUnstructuredAnswerComposer
    OPENAI_MODEL = "gpt-3.5-turbo".freeze

    def self.call(...) = new(...).call

    def initialize(context)
      @context = context
    end

    def call
      message = openai_response.dig("choices", 0, "message", "content")
      context.answer.assign_attributes(
        message:,
        status: "success",
        llm_response: message,
      )
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
        { role: "system", content: system_prompt },
        few_shots,
        { role: "user", content: context.question_message },
      ]
      .flatten
    end

    def system_prompt
      sprintf(llm_prompts.answer_composition.compose_answer.system_prompt, context: system_prompt_context)
    end

    def system_prompt_context
      context.search_results.map { |result|
        [
          result.title,
          result.heading_hierarchy,
          result.description,
          result.html_content,
        ]
        .flatten
        .compact
        .join("\n")
      }
      .join("\n\n")
    end

    def few_shots
      llm_prompts.answer_composition.compose_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end

    def openai_client
      @openai_client ||= OpenAIClient.build
    end
  end
end
