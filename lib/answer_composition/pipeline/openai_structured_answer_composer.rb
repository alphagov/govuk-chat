module AnswerComposition::Pipeline
  class OpenAIStructuredAnswerComposer
    OPENAI_MODEL = "gpt-4o".freeze

    def self.call(...) = new(...).call

    def initialize(context)
      @context = context
    end

    def call
      unless parsed_structured_response["answered"]
        return context.abort_pipeline!(
          message: Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE,
          status: "abort_llm_cannot_answer",
          llm_response: raw_structured_response,
        )
      end

      message = if parsed_structured_response["call_for_action"].present?
                  "#{parsed_structured_response['answer']}\n\n#{parsed_structured_response['call_for_action']}"
                else
                  parsed_structured_response["answer"]
                end

      context.update_sources_from_exact_paths_used(parsed_structured_response["sources_used"])
      context.answer.assign_attributes(
        message:,
        status: "success",
        llm_response: raw_structured_response,
      )
    rescue JSON::Schema::ValidationError => e
      context.abort_pipeline!(
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_invalid_llm_response",
        error_message: error_message(e),
        llm_response: raw_structured_response,
      )
    rescue JSON::ParserError => e
      context.abort_pipeline!(
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_invalid_llm_response",
        error_message: error_message(e),
        llm_response: raw_structured_response,
      )
    end

  private

    attr_reader :context

    def parsed_structured_response
      @parsed_structured_response ||= begin
        parsed_structured_response = JSON.parse(raw_structured_response)
        JSON::Validator.validate!(output_schema, parsed_structured_response)
        parsed_structured_response
      end
    end

    def raw_structured_response
      @raw_structured_response ||= openai_response.dig(
        "choices", 0, "message", "tool_calls", 0, "function", "arguments"
      )
    end

    def openai_response
      openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          tools: [
            {
              type: "function",
              function: {
                "name": "generate_answer_using_retrieved_contexts",
                "description": "Use the provided contexts to generate an answer to the question.",
                "parameters": {
                  "type": output_schema[:type],
                  "properties": output_schema[:properties],
                },
                "required": output_schema[:required],
              },
            },
          ],
          tool_choice: "required",
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
      sprintf(llm_prompts.openai_structured_answer.system_prompt, context: system_prompt_context)
    end

    def system_prompt_context
      context.search_results.map do |result|
        {
          page_url: result.exact_path,
          page_title: result.title,
          page_description: result.description,
          context_headings: result.heading_hierarchy,
          context_content: result.html_content,
        }
      end
    end

    def few_shots
      llm_prompts.openai_structured_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end
    end

    def output_schema
      llm_prompts.openai_structured_answer.output_schema
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end

    def openai_client
      @openai_client ||= OpenAIClient.build
    end

    def error_message(error)
      "class: #{error.class} message: #{error.message}"
    end
  end
end
