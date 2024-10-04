module AnswerComposition
  module Pipeline
    class QuestionRouter
      class InvalidLabelError < StandardError; end

      OPENAI_MODEL = "gpt-4o-mini".freeze

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = AnswerComposition.monotonic_time
        context.answer.assign_llm_response("question_routing", openai_response_choice)

        if valid_question?
          context.answer.assign_attributes(question_routing_label: "genuine_rag")
          context.answer.assign_metrics("question_routing", build_metrics(start_time))
        else
          validate_schema

          context.abort_pipeline!(
            message: llm_classification_data["answer"],
            status: "abort_question_routing",
            question_routing_label:,
            question_routing_confidence_score: llm_classification_data["confidence"],
            metrics: { "question_routing" => build_metrics(start_time) },
          )
        end
      rescue JSON::Schema::ValidationError, JSON::ParserError => e
        context.abort_pipeline!(
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          status: "error_question_routing",
          error_message: error_message(e),
          metrics: { "question_routing" => build_metrics(start_time) },
        )
      end

    private

      attr_reader :context

      def valid_question?
        question_routing_label == "genuine_rag"
      end

      def question_routing_label
        llm_classification_function["name"]
      end

      def llm_classification_function
        @llm_classification_function ||= openai_response_choice.dig(
          "message", "tool_calls", 0, "function"
        )
      end

      def openai_response_choice
        @openai_response_choice ||= openai_response.dig("choices", 0)
      end

      def raw_llm_classification_data
        llm_classification_function["arguments"]
      end

      def llm_classification_data
        JSON.parse(raw_llm_classification_data)
      end

      def validate_schema
        used_tool = tools.find do |tool|
          tool[:function][:name] == question_routing_label
        end

        raise InvalidLabelError, "Invalid label: #{question_routing_label}" unless used_tool

        schema = used_tool[:function][:parameters]
        JSON::Validator.validate!(schema, JSON.parse(raw_llm_classification_data))
      end

      def openai_response
        @openai_response ||= openai_client.chat(
          parameters: {
            model: OPENAI_MODEL,
            messages:,
            temperature: 0.0,
            tools:,
            tool_choice: "required",
            parallel_tool_calls: false,
          },
        )
      end

      def messages
        [
          { role: "system", content: config[:system_prompt] },
          { role: "user", content: context.question_message },
        ]
      end

      def config
        Rails.configuration.llm_prompts.question_routing
      end

      def openai_client
        @openai_client ||= OpenAIClient.build
      end

      def tools
        config[:classifications].map do |classification|
          {
            type: "function",
            function: {
              name: classification[:name],
              description: build_description(classification),
              strict: true,
              parameters: {
                type: "object",
                properties: classification[:properties].merge(
                  confidence: config[:confidence_property],
                ),
                required: classification[:required] + %w[confidence],
                additionalProperties: false,
              },
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

          example_string = value.map { |str| "'#{str}'" }.join(", ")
          description << config["description_#{key}_template"].sub("{examples}", example_string).strip
        end

        description.compact.join(" ")
      end

      def error_message(error)
        "class: #{error.class} message: #{error.message}"
      end

      def build_metrics(start_time)
        {
          duration: AnswerComposition.monotonic_time - start_time,
          llm_prompt_tokens: openai_response.dig("usage", "prompt_tokens"),
          llm_completion_tokens: openai_response.dig("usage", "completion_tokens"),
        }
      end
    end
  end
end
