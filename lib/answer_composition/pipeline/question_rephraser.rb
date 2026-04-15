module AnswerComposition
  module Pipeline
    class QuestionRephraser
      Result = Data.define(:llm_response, :rephrased_question, :metrics)

      SUPPORTED_MODELS = %i[claude_sonnet_4_0 claude_sonnet_4_5].freeze
      DEFAULT_MODEL = :claude_sonnet_4_0

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
        @model_id, @model_name = BedrockModels.determine_model(
          ENV["BEDROCK_CLAUDE_QUESTION_REPHRASER_MODEL"],
          DEFAULT_MODEL,
          SUPPORTED_MODELS,
        )
      end

      def call
        return if message_records.blank?

        start_time = Clock.monotonic_time
        response = anthropic_bedrock_client.messages.create(
          system: [{ type: "text", text: config[:system_prompt] }],
          model: model_id,
          messages:,
          **inference_config,
        )

        context.answer.assign_llm_response("question_rephrasing", response.to_h)
        context.question_message = response[:content][0][:text]
        context.answer.assign_metrics(
          "question_rephrasing",
          { duration: Clock.monotonic_time - start_time }.merge(build_metrics(response)),
        )
      end

    private

      attr_reader :context, :model_id, :model_name

      def question_message
        context.question.message
      end

      def message_records
        @message_records ||= Question.where(conversation: context.question.conversation)
                                     .includes(:answer)
                                     .joins(:answer)
                                     .last(5)
                                     .select(&:use_in_rephrasing?)
      end

      def anthropic_bedrock_client
        @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
          aws_region: ENV["CLAUDE_AWS_REGION"],
        )
      end

      def build_metrics(response)
        {
          llm_prompt_tokens: response[:usage][:input_tokens],
          llm_completion_tokens: response[:usage][:output_tokens],
          llm_cached_tokens: nil,
          model: response[:model],
        }
      end

      def config
        Claude.prompt_config(:question_rephraser, model_name)
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
        [{ role: "user", content: user_prompt }]
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
