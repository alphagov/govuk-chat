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
        response = anthropic_bedrock_client.messages.create(
          system: [
            { type: "text", text: cached_system_prompt, cache_control: { type: "ephemeral" } },
            { type: "text", text: context_system_prompt },
          ],
          model: BedrockModels.model_id(:claude_sonnet),
          messages:,
          tools: tools,
          tool_choice: { type: "tool", name: "output_schema" },
          **inference_config,
        )

        context.answer.assign_llm_response("structured_answer", response.to_h)
        tool_output = response[:content][0][:input]

        unless tool_output[:answered]
          return context.abort_pipeline!(
            message: Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE,
            status: "unanswerable_llm_cannot_answer",
            metrics: { "structured_answer" => build_metrics(start_time, response) },
          )
        end

        set_context_sources(tool_output[:sources_used])
        message = link_token_mapper.replace_tokens_with_links(tool_output[:answer])
        context.answer.assign_attributes(message:, status: "answered")
        context.answer.assign_metrics("structured_answer", build_metrics(start_time, response))
      end

    private

      attr_reader :context, :link_token_mapper

      def messages
        [
          {
            role: "user",
            content: context.question_message,
          },
        ]
      end

      def inference_config
        {
          max_tokens: 4096,
          temperature: 0.0,
        }
      end

      def cached_system_prompt
        prompt_config[:cached_system_prompt]
      end

      def context_system_prompt
        sprintf(
          prompt_config[:context_system_prompt],
          context: context.search_results_prompt_formatted(link_token_mapper),
        )
      end

      def prompt_config
        Claude.prompt_config.structured_answer
      end

      def anthropic_bedrock_client
        @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
          aws_region: ENV["CLAUDE_AWS_REGION"],
        )
      end

      def set_context_sources(sources_used)
        source_urls = sources_used.map do |source_link_token|
          link_token_mapper.link_for_token(source_link_token)
        end

        context.update_sources_from_exact_urls_used(source_urls)
      end

      def build_metrics(start_time, response)
        {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: BedrockModels.claude_total_prompt_tokens(response[:usage]),
          llm_completion_tokens: response[:usage][:output_tokens],
          llm_cached_tokens: response[:usage][:cache_read_input_tokens],
          model: response[:model],
        }
      end

      def tool_config
        {
          tools: tools,
          tool_choice: {
            tool: { name: "output_schema" },
          },
        }
      end

      def tools
        [prompt_config[:tool_spec]]
      end
    end
  end
end
