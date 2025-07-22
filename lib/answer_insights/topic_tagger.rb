class AnswerInsights::TopicTagger
  delegate :logger, to: Rails

  attr_reader :answer

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
  end

  def call
    start_time = Clock.monotonic_time
    if answer&.analysis&.primary_topic.present?
      return logger.warn("Topics already generated for answer #{answer.id}")
    end

    response = anthropic_bedrock_client.messages.create(
      messages:,
      system: [
        { type: "text", text: system_prompt, cache_control: { type: "ephemeral" } },
      ],
      model: BedrockModels::CLAUDE_SONNET,
      tools:,
      tool_choice: { type: "tool", name: tools.first[:name] },
      **inference_config,
    )

    answer.create_analysis(
      primary_topic: response[:content][0][:input][:primary_topic],
      secondary_topic: response[:content][0][:input][:secondary_topic],
      metrics: build_metrics(response, start_time),
      llm_responses: { topic_tagger: response.to_h },
    )
  end

private

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
    sprintf(
      topic_tagger_config["system_prompt"],
      topics:,
    )
  end

  def messages
    [
      {
        role: "user",
        content: answer.rephrased_question || answer.question.message,
      },
    ]
  end

  def topics
    topic_tagger_config["topics"].map { |topic, description|
      "#{topic} - #{description}"
    }
    .join("\n")
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
