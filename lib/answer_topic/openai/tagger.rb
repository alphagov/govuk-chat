class AnswerTopic::OpenAI::Tagger
  MODEL = "gpt-4o-mini".freeze

  delegate :logger, to: Rails

  attr_reader :answer

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
  end

  def call
    start_time = Clock.monotonic_time
    return logger.warn("Topics already generated for answer #{answer.id}") if answer.topic.present?

    answer.create_topic(
      primary: parsed_structured_response["primary_topic"],
      secondary: parsed_structured_response["secondary_topic"],
      metrics: build_metrics(start_time),
      llm_response: openai_response_choice,
    )
  end

private

  def openai_client
    @openai_client ||= OpenAIClient.build
  end

  def openai_response
    @openai_response ||= openai_client.chat(
      parameters: {
        model: MODEL,
        messages:,
        temperature: 0.0,
        tools:,
        tool_choice: "required",
        parallel_tool_calls: false,
      },
    )
  end

  def openai_response_choice
    @openai_response_choice ||= openai_response.dig("choices", 0)
  end

  def raw_structured_response
    @raw_structured_response ||= openai_response_choice.dig(
      "message", "tool_calls", 0, "function", "arguments"
    )
  end

  def parsed_structured_response
    @parsed_structured_response ||= JSON.parse(raw_structured_response)
  end

  def build_metrics(start_time)
    {
      duration: Clock.monotonic_time - start_time,
      llm_prompt_tokens: openai_response.dig("usage", "prompt_tokens"),
      llm_completion_tokens: openai_response.dig("usage", "completion_tokens"),
      llm_cached_tokens: openai_response.dig("usage", "prompt_tokens_details", "cached_tokens"),
      model: openai_response["model"],
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
        role: "system",
        content: system_prompt,
      },
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

  def tools
    [
      {
        type: "function",
        function: {
          name: "topic_tagger",
          description: "Tags a question with primary and optional secondary GOV.UK topics, including confidence and reasoning.",
          parameters: output_schema,
        },
      },
    ]
  end

  def output_schema
    topics_config.openai_output_schema
  end
end
