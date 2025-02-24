module AnswerComposition::Pipeline
  module Claude
    class QuestionRouter
      BEDROCK_MODEL = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0".freeze

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = Clock.monotonic_time

        answer = context.answer
        answer.assign_llm_response("question_routing", bedrock_response)

        if genuine_rag?
          answer.assign_attributes(
            question_routing_label:,
            question_routing_confidence_score: llm_classification_data["confidence"],
          )
        else
          answer.assign_attributes(
            message: use_llm_answer? ? llm_answer : Answer::CannedResponses.response_for_question_routing_label(question_routing_label),
            status: answer_status,
            question_routing_label:,
            question_routing_confidence_score: llm_classification_data["confidence"],
          )

          context.abort_pipeline unless use_llm_answer?
        end

        answer.assign_metrics("question_routing", build_metrics(start_time))
      end

    private

      attr_reader :context

      def label_config
        Rails.configuration.question_routing_labels.fetch(question_routing_label)
      end

      def use_llm_answer?
        return false if token_limit_reached?

        label_config[:use_answer]
      end

      def token_limit_reached?
        bedrock_response["stop_reason"] == "max_tokens"
      end

      def answer_status
        label_config[:answer_status]
      end

      def llm_answer
        llm_classification_data["answer"]
      end

      def genuine_rag?
        question_routing_label == "genuine_rag"
      end

      def question_routing_label
        llm_classification_function["name"]
      end

      def llm_classification_function
        tool_use = bedrock_response["content"].detect { it["type"] == "tool_use" }

        raise "No tool use" if tool_use.nil?

        tool_use
      end

      def llm_classification_data
        llm_classification_function["input"]
      end

      def bedrock_client
        @bedrock_client ||= Aws::BedrockRuntime::Client.new
      end

      def bedrock_response
        @bedrock_response ||= begin
          response = bedrock_client.invoke_model(
            model_id: BEDROCK_MODEL,
            content_type: "application/json",
            accept: "application/json",
            body: JSON.generate({
              messages:,
              max_tokens: 4096,
              system: prompt_config[:system_prompt],
              anthropic_version: "bedrock-2023-05-31",
              tools:,
            }),
          )
          JSON.parse(response.body.string)
        end
      end

      def messages
        [
          { role: "user", content: [{ type: "text", text: context.question_message }] },
        ]
      end

      def prompt_config
        Claude.prompt_config.question_routing
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
          llm_prompt_tokens: bedrock_response.dig("usage", "input_tokens"),
          llm_completion_tokens: bedrock_response.dig("usage", "output_tokens"),
        }
      end
    end
  end
end
