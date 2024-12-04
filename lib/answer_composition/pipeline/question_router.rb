module AnswerComposition
  module Pipeline
    class QuestionRouter
      OPENAI_MODEL = "gpt-4o-mini".freeze
      MAX_COMPLETION_TOKENS = 160

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
      end

      def call
        start_time = Clock.monotonic_time

        answer = context.answer
        answer.assign_llm_response("question_routing", openai_response_choice)

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

        answer.assign_metrics(
          "question_routing", build_metrics(start_time)
        )
      end

    private

      attr_reader :context

      def label_config
        Rails.configuration.question_routing_labels[question_routing_label]
      end

      def use_llm_answer?
        return false if openai_token_limit_reached?

        label_config[:use_answer]
      end

      def answer_status
        label_config[:answer_status]
      end

      def openai_token_limit_reached?
        openai_response_choice["finish_reason"] == "length"
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

      def openai_response
        @openai_response ||= openai_client.chat(
          parameters: {
            model: OPENAI_MODEL,
            messages:,
            temperature: 0.0,
            tools:,
            tool_choice: "required",
            parallel_tool_calls: false,
            max_completion_tokens: MAX_COMPLETION_TOKENS,
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
          parameters = {
            type: "object",
            additionalProperties: false,
            properties: {
              confidence: config[:confidence_property],
            },
            required: %w[confidence],
          }

          if classification[:properties].present?
            parameters[:required].concat(classification[:required])
            parameters[:properties].merge!(classification[:properties])
          end

          {
            type: "function",
            function: {
              name: classification[:name],
              description: build_description(classification),
              strict: true,
              parameters:,
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
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: openai_response.dig("usage", "prompt_tokens"),
          llm_completion_tokens: openai_response.dig("usage", "completion_tokens"),
          llm_cached_tokens: openai_response.dig("usage", "prompt_tokens_details", "cached_tokens"),
        }
      end
    end
  end
end
