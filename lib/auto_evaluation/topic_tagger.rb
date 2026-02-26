module AutoEvaluation
  class TopicTagger
    Result = Data.define(:primary_topic,
                         :secondary_topic,
                         :metrics,
                         :llm_response)

    def self.call(...) = new(...).call

    def initialize(user_question)
      @user_question = user_question
    end

    def call
      start_time = Clock.monotonic_time
      response = anthropic_bedrock_client.messages.create(
        messages:,
        system: [
          { type: "text", text: system_prompt, cache_control: { type: "ephemeral" } },
        ],
        model: BedrockModels.model_id(:claude_sonnet_4_0),
        tools:,
        tool_choice: { type: "tool", name: tools.first[:name] },
        **inference_config,
      )

      Result.new(
        primary_topic: response[:content][0][:input][:primary_topic],
        secondary_topic: response[:content][0][:input][:secondary_topic],
        metrics: build_metrics(response, start_time),
        llm_response: response.to_h,
      )
    end

  private

    attr_reader :user_question

    def anthropic_bedrock_client
      @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
        aws_region: ENV["CLAUDE_AWS_REGION"],
      )
    end

    def build_metrics(response, start_time)
      {
        duration: Clock.monotonic_time - start_time,
        llm_prompt_tokens: BedrockModels.claude_total_prompt_tokens(response[:usage]),
        llm_completion_tokens: response[:usage][:output_tokens],
        llm_cached_tokens: response[:usage][:cache_read_input_tokens],
        model: response[:model],
      }
    end

    def system_prompt
      topic_tagger_config["system_prompt"]
    end

    def messages
      [
        {
          role: "user",
          content: user_question,
        },
      ]
    end

    def topic_tagger_config
      Rails.configuration.govuk_chat_private.llm_prompts.claude.topic_tagger
    end

    def inference_config
      {
        max_tokens: 4096,
        temperature: 0.0,
      }
    end

    def tools
      [topic_tagger_config["tool_spec"]]
    end
  end
end
