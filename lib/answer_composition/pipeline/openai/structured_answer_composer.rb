module AnswerComposition::Pipeline::OpenAI
  class StructuredAnswerComposer
    OPENAI_MODEL = "gpt-4o-2024-08-06".freeze

    def self.call(...) = new(...).call

    def initialize(context)
      @context = context
      @link_token_mapper = AnswerComposition::LinkTokenMapper.new
    end

    def call
      start_time = Clock.monotonic_time
      llm_response_with_link_token_mapping = {
        "response" => openai_response_choice,
        "link_token_mapping" => link_token_mapper.mapping.invert,
      }
      context.answer.assign_llm_response("structured_answer", llm_response_with_link_token_mapping)

      unless parsed_structured_response["answered"]
        return context.abort_pipeline!(
          message: Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE,
          status: "unanswerable_llm_cannot_answer",
          metrics: { "structured_answer" => build_metrics(start_time) },
        )
      end

      message = link_token_mapper.replace_tokens_with_links(parsed_structured_response["answer"])
      set_context_sources

      context.answer.assign_attributes(message:, status: "answered")
      context.answer.assign_metrics("structured_answer", build_metrics(start_time))
    end

  private

    attr_reader :context, :link_token_mapper

    def parsed_structured_response
      @parsed_structured_response ||= JSON.parse(raw_structured_response)
    end

    def raw_structured_response
      @raw_structured_response ||= openai_response_choice.dig(
        "message", "tool_calls", 0, "function", "arguments"
      )
    end

    def openai_response
      @openai_response ||= openai_client.chat(
        parameters: {
          model: OPENAI_MODEL,
          messages:,
          temperature: 0.0,
          tools: [
            {
              type: "function",
              function: {
                name: "generate_answer_using_retrieved_contexts",
                description: "Use the provided contexts to generate an answer to the question.",
                strict: true,
                parameters: output_schema,
              },
            },
          ],
          tool_choice: "required",
          parallel_tool_calls: false,
        },
      )
    end

    def openai_response_choice
      @openai_response_choice ||= openai_response.dig("choices", 0)
    end

    def messages
      [
        { role: "system", content: system_prompt },
        { role: "user", content: context.question_message },
      ]
      .flatten
    end

    def system_prompt
      sprintf(
        openai_prompts[:system_prompt],
        context: context.search_results_prompt_formatted(link_token_mapper),
      )
    end

    def output_schema
      openai_prompts[:output_schema]
    end

    def openai_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.openai.structured_answer
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

      context.update_sources_from_exact_urls_used(source_urls)
    end

    def build_metrics(start_time)
      {
        duration: Clock.monotonic_time - start_time,
        llm_prompt_tokens: openai_response.dig("usage", "prompt_tokens"),
        llm_completion_tokens: openai_response.dig("usage", "completion_tokens"),
        llm_cached_tokens: openai_response.dig("usage", "prompt_tokens_details", "cached_tokens"),
        model: openai_response["model"],
      }
    end
  end
end
