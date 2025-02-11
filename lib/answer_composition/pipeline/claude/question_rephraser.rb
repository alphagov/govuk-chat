module AnswerComposition::Pipeline
  module Claude
    class QuestionRephraser
      # TODO: change this to a more basic model
      BEDROCK_MODEL = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0".freeze

      def self.call(...) = new(...).call

      def initialize(question_message, message_records)
        @question_message = question_message
        @message_records = message_records
      end

      def call
        response = bedrock_client.converse(
          system: [{ text: config[:system_prompt] }],
          model_id: BEDROCK_MODEL,
          messages:,
          inference_config:,
        )

        AnswerComposition::Pipeline::QuestionRephraser::Result.new(
          llm_response: response.to_h,
          rephrased_question: response.dig("output", "message", "content", 0, "text"),
          metrics: build_metrics(response),
        )
      end

    private

      attr_reader :question_message, :message_records

      def bedrock_client
        @bedrock_client ||= Aws::BedrockRuntime::Client.new
      end

      def build_metrics(response)
        {
          llm_prompt_tokens: response.dig("usage", "input_tokens"),
          llm_completion_tokens: response.dig("usage", "output_tokens"),
        }
      end

      def config
        Claude.prompt_config[:question_rephraser]
      end

      def inference_config
        {
          max_tokens: 4096,
          temperature: 0.0,
        }
      end

      def user_prompt
        config[:user_prompt]
          .sub("{question}", question_message)
          .sub("{message_history}", message_history)
      end

      def messages
        [{ role: "user", content: [{ text: user_prompt }] }]
      end

      def message_history
        message_records.flat_map(&method(:map_question)).join("\n")
      end

      def map_question(question)
        question_message = question.answer.rephrased_question || question.message

        [
          format_messsage("user", question_message),
          format_messsage("assistant", question.answer.message),
        ]
      end

      def format_messsage(actor, message)
        ["#{actor}:", '"""', message, '"""'].join("\n")
      end
    end
  end
end
