module AnswerComposition::Pipeline
  module Claude
    class QuestionRouter
      SUPPORTED_MODELS = %i[claude_sonnet_4_0 claude_haiku_4_5].freeze
      DEFAULT_MODEL = :claude_sonnet_4_0

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
        @model_id, @model_name = BedrockModels.determine_model(
          ENV["BEDROCK_CLAUDE_QUESTION_ROUTER_MODEL"],
          DEFAULT_MODEL,
          SUPPORTED_MODELS,
        )
      end

      def call
        start_time = Clock.monotonic_time
        answer = context.answer
        answer.assign_llm_response("question_routing", claude_response.to_h)

        if genuine_rag?
          answer.assign_attributes(
            question_routing_label:,
            question_routing_confidence_score: llm_classification_data[:confidence],
          )
        else
          answer.assign_attributes(
            message: use_llm_answer? ? llm_answer : Answer::CannedResponses.response_for_question_routing_label(question_routing_label),
            status: answer_status,
            question_routing_label:,
            question_routing_confidence_score: llm_classification_data[:confidence],
          )

          context.abort_pipeline unless use_llm_answer?
        end

        answer.assign_metrics("question_routing", build_metrics(start_time))
      end

    private

      attr_reader :context, :model_id, :model_name

      def label_config
        Rails.configuration.question_routing_labels.fetch(question_routing_label)
      end

      def use_llm_answer?
        return false if token_limit_reached?

        label_config[:use_answer]
      end

      def token_limit_reached?
        claude_response[:stop_reason] == :max_tokens
      end

      def answer_status
        label_config[:answer_status]
      end

      def llm_answer
        llm_classification_data[:answer]
      end

      def genuine_rag?
        question_routing_label == "genuine_rag"
      end

      def question_routing_label
        llm_classification_function[:name]
      end

      def llm_classification_function
        @llm_classification_function ||= claude_response[:content][0]
      end

      def llm_classification_data
        llm_classification_function[:input]
      end

      def anthropic_bedrock_client
        @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
          aws_region: ENV["CLAUDE_AWS_REGION"],
        )
      end

      def claude_response
        @claude_response ||= anthropic_bedrock_client.messages.create(
          system: [
            { type: "text", text: prompt_config[:system_prompt], cache_control: { type: "ephemeral" } },
          ],
          model: model_id,
          messages:,
          tools:,
          tool_choice: { type: "any", disable_parallel_tool_use: true },
          **inference_config,
        )
      end

      def inference_config
        {
          max_tokens: 500, # A small limit here removes the risk of the LLM returning the whole prompt verbatim
          temperature: 0.0,
        }
      end

      def messages
        [
          { role: "user", content: context.question_message },
        ]
      end

      def prompt_config
        Claude.prompt_config(:question_routing, model_name)
      end

      def tool_config
        {
          tools:,
          tool_choice: { any: {} },
        }
      end

      def tools
        prompt_config[:classifications].map do |classification|
          properties = {
            confidence: prompt_config[:confidence_property],
          }
          required = %w[confidence]

          if classification[:properties].present?
            required.concat(classification[:required])
            properties.merge!(classification[:properties])
          end

          {
            name: classification[:name],
            description: build_description(classification),
            input_schema: {
              type: "object",
              properties:,
              required:,
            },
          }
        end
      end

      def build_description(classification)
        description = [classification[:description].strip]

        examples = {
          positive_examples: Array(classification[:examples]),
          negative_examples: Array(classification[:negative_examples]),
        }

        examples.each do |key, value|
          next unless value.any?

          example_string = value.map { "'#{it}'" }.join(", ")
          description << prompt_config["description_#{key}_template"].sub("{examples}", example_string).strip
        end

        description.compact.join(" ")
      end

      def build_metrics(start_time)
        {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: BedrockModels.claude_total_prompt_tokens(claude_response[:usage]),
          llm_completion_tokens: claude_response[:usage][:output_tokens],
          llm_cached_tokens: claude_response[:usage][:cache_read_input_tokens],
          model: claude_response[:model],
        }
      end
    end
  end
end
