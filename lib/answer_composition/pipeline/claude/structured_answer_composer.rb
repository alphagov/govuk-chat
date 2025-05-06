module AnswerComposition::Pipeline
  module Claude
    class StructuredAnswerComposer
      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
        @link_token_mapper = AnswerComposition::LinkTokenMapper.new
      end

      def call
        start_time = Clock.monotonic_time

        response = bedrock_client.converse(
          system: [{ text: system_prompt }],
          model_id: BedrockModels::CLAUDE_3_7_SONNET,
          messages:,
          inference_config:,
          tool_config:,
        )

        tool_output = response.dig("output", "message", "content", 0, "tool_use", "input")

        unless tool_output["answered"]
          return context.abort_pipeline!(
            message: Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE,
            status: "unanswerable_llm_cannot_answer",
            metrics: { "structured_answer" => build_metrics(start_time, response) },
          )
        end

        set_context_sources(tool_output["sources_used"])

        context.answer.assign_llm_response("structured_answer", response.to_h)
        message = link_token_mapper.replace_tokens_with_links(tool_output["answer"])
        context.answer.assign_attributes(message:, status: "answered")
        context.answer.assign_metrics("structured_answer", build_metrics(start_time, response))
      end

    private

      attr_reader :context, :link_token_mapper

      def messages
        [
          {
            role: "user",
            content: [{ text: context.question_message }],
          },
        ]
      end

      def inference_config
        {
          max_tokens: 4096,
          temperature: 0.0,
        }
      end

      def system_prompt
        sprintf(
          prompt_config[:system_prompt],
          context: context.search_results_prompt_formatted(link_token_mapper),
        )
      end

      def prompt_config
        Claude.prompt_config[:structured_answer]
      end

      def bedrock_client
        @bedrock_client ||= Aws::BedrockRuntime::Client.new
      end

      def set_context_sources(sources_used)
        source_urls = sources_used.map do |source_link_token|
          link_token_mapper.link_for_token(source_link_token)
        end

        context.update_sources_from_exact_paths_used(source_urls)
      end

      def build_metrics(start_time, response)
        {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: response.dig("usage", "input_tokens"),
          llm_completion_tokens: response.dig("usage", "output_tokens"),
        }
      end

      def tool_config
        {
          tools: tools,
          tool_choice: {
            tool: {
              name: "output_schema",
            },
          },
        }
      end

      def tools
        [{ tool_spec: prompt_config[:tool_spec] }]
      end
    end
  end
end
