class AnswerTopic::Claude::Tagger
  delegate :logger, to: Rails

  attr_reader :answer

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
  end

  def call
    start_time = Clock.monotonic_time
    return logger.warn("Topics already generated for answer #{answer.id}") if answer.topic.present?

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

    answer.create_topic(
      primary: response[:content][0][:input][:primary_topic],
      secondary: response[:content][0][:input][:secondary_topic],
      metrics: build_metrics(response, start_time),
      llm_response: response,
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
      topics_config.system_prompt,
      topics:,
    )
  end

  def messages
    [
      {
        role: "assistant",
        content: answer.message,
      },
    ]
  end

  def topics
    topics_config.topics.map { |topic, description|
      "#{topic} - #{description}"
    }
    .join("\n")
  end

  def topics_config
    Rails.application.config.answer_topic
  end

  def inference_config
    {
      max_tokens: 4096,
      temperature: 0.0,
    }
  end

  def tools
    [topics_config[:tool_spec]]
  end
end
