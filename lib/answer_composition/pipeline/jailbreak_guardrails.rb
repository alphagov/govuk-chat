module AnswerComposition
  module Pipeline
    class JailbreakGuardrails
      SUPPORTED_MODELS = %i[claude_sonnet_4_0 claude_haiku_4_5].freeze
      DEFAULT_MODEL = :claude_sonnet_4_0

      def self.call(...) = new(...).call

      def initialize(context)
        @context = context
        @model_id, @model_name = BedrockModels.determine_model(
          ENV["BEDROCK_CLAUDE_JAILBREAK_GUARDRAILS_MODEL"],
          DEFAULT_MODEL,
          SUPPORTED_MODELS,
        )
      end

      def call
        start_time = Clock.monotonic_time
        response = anthropic_bedrock_client.messages.create(
          system: [{ type: "text", text: system_prompt }],
          model: model_id,
          messages:,
          **inference_config,
        )

        text_response = response[:content][0][:text]
        jailbreak_guardrails_status = case text_response
                                      when pass_value
                                        :pass
                                      when fail_value
                                        :fail
                                      else
                                        :error
                                      end

        context.answer.assign_attributes(jailbreak_guardrails_status:)
        context.answer.assign_llm_response("jailbreak_guardrails", response.to_h)
        context.answer.assign_metrics("jailbreak_guardrails", build_metrics(start_time, response))

        if jailbreak_guardrails_status == :error
          context.abort_pipeline!(
            message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
            status: "error_jailbreak_guardrails",
          )
        end

        if jailbreak_guardrails_status == :fail
          context.abort_pipeline!(
            message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
            status: "guardrails_jailbreak",
          )
        end
      end

    private

      attr_reader :context, :model_id, :model_name

      def anthropic_bedrock_client
        @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
          aws_region: ENV["CLAUDE_AWS_REGION"],
        )
      end

      def guardrails_llm_prompts
        AnswerComposition::Pipeline::Claude.prompt_config(:jailbreak_guardrails, model_name)
      end

      # TODO: Move the common prompts into the claude config and use one set of prompts here.
      def common_guardrails_llm_prompts
        Rails.configuration.govuk_chat_private.llm_prompts.common.jailbreak_guardrails
      end

      def pass_value
        common_guardrails_llm_prompts.fetch(:pass_value)
      end

      def fail_value
        common_guardrails_llm_prompts.fetch(:fail_value)
      end

      def max_tokens
        guardrails_llm_prompts.fetch(:max_tokens)
      end

      def inference_config
        {
          max_tokens: max_tokens,
          temperature: 0.0,
        }
      end

      def messages
        [{ role: "user", content: user_prompt }]
      end

      def user_prompt
        guardrails_llm_prompts[:user_prompt].sub("{input}", context.question.message)
      end

      def system_prompt
        guardrails_llm_prompts[:system_prompt]
      end

      def build_metrics(start_time, response)
        {
          duration: Clock.monotonic_time - start_time,
          llm_prompt_tokens: response[:usage][:input_tokens],
          llm_completion_tokens: response[:usage][:output_tokens],
          llm_cached_tokens: nil,
          model: response[:model],
        }
      end
    end
  end
end
