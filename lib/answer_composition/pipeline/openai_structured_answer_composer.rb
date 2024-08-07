module AnswerComposition::Pipeline
  class OpenAIStructuredAnswerComposer
    OPENAI_MODEL = "gpt-4o".freeze

    def self.call(...) = new(...).call

    def initialize(context)
      @context = context
      @link_token_mapper = AnswerComposition::LinkTokenMapper.new
    end

    def call
      unless parsed_structured_response["answered"]
        return context.abort_pipeline!(
          message: Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE,
          status: "abort_llm_cannot_answer",
          llm_response: raw_structured_response,
        )
      end

      message = link_token_mapper.replace_tokens_with_links(parsed_structured_response["answer"])

      set_context_sources

      context.answer.assign_attributes(
        message:,
        status: "success",
        llm_response: raw_structured_response,
      )
    rescue JSON::Schema::ValidationError, JSON::ParserError => e
      context.abort_pipeline!(
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_invalid_llm_response",
        error_message: error_message(e),
        llm_response: raw_structured_response,
      )
    end

  private

    attr_reader :context, :link_token_mapper

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
      sprintf(llm_prompts[:system_prompt], context: system_prompt_context)
    end

    def system_prompt_context
      context.search_results.map do |result|
        {
          page_url: link_token_mapper.map_link_to_token(result.exact_path),
          page_title: result.title,
          page_description: result.description,
          context_headings: result.heading_hierarchy,
          context_content: link_token_mapper.map_links_to_tokens(result.html_content),
        }
      end
    end

    def few_shots
      llm_prompts[:few_shots].flat_map do |few_shot|
        [
          { role: "user", content: few_shot[:user] },
          { role: "assistant", content: few_shot[:assistant] },
        ]
      end
    end

    def output_schema
      llm_prompts[:output_schema]
    end

    def llm_prompts
      Rails.configuration.llm_prompts.openai_structured_answer
    end

    def openai_client
      @openai_client ||= OpenAIClient.build
    end

    def error_message(error)
      "class: #{error.class} message: #{error.message}"
    end

    def set_context_sources
      source_urls = parsed_structured_response["sources_used"].map do |source_link_token|
        link_token_mapper.link_for_token(source_link_token)
      end

      context.update_sources_from_exact_paths_used(source_urls)
    end
  end
end
