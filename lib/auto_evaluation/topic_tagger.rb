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
      result = BedrockOpenAIOssInvoke.call(user_question, tools, system_prompt)
      Result.new(
        primary_topic: result.evaluation_data.fetch("primary_topic"),
        secondary_topic: result.evaluation_data.fetch("secondary_topic"),
        metrics: result.metrics,
        llm_response: result.llm_response,
      )
    end

  private

    attr_reader :user_question

    def anthropic_bedrock_client
      @anthropic_bedrock_client ||= Anthropic::BedrockClient.new(
        aws_region: ENV["CLAUDE_AWS_REGION"],
      )
    end

    def topic_tagger_config
      Prompts.config.topic_tagger
    end

    def system_prompt
      topic_tagger_config.fetch("system_prompt")
    end

    def tools
      [topic_tagger_config.fetch("tool_spec")]
    end
  end
end
