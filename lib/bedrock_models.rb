module BedrockModels
  MODEL_IDS = {
    claude_sonnet_4_0: "eu.anthropic.claude-sonnet-4-20250514-v1:0",
    titan_embed_v2: "amazon.titan-embed-text-v2:0",
    openai_gpt_oss_120b: "openai.gpt-oss-120b-1:0",
  }.freeze

  def self.model_id(model_name)
    MODEL_IDS.fetch(model_name) { raise "Unknown Bedrock model name: #{model_name}" }
  end

  def self.expected_foundation_models
    # Strip the "eu." prefix from the model name we use if it exists. We
    # sometimes use this prefix in our model names if we're using cross-region
    # inference for that model. But the Bedrock API returns the model names without
    # this region prefix.
    MODEL_IDS.values.map { it.sub(/^eu\./, "") }
  end

  def self.claude_total_prompt_tokens(usage)
    usage[:input_tokens].to_i + usage[:cache_read_input_tokens].to_i + usage[:cache_write_input_tokens].to_i
  end
end
