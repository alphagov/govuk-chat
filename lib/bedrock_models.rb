module BedrockModels
  CLAUDE_SONNET = ENV.fetch("CLAUDE_SONNET_MODEL_ID", "eu.anthropic.claude-sonnet-4-20250514-v1:0").freeze
  TITAN_EMBED_V2 = "amazon.titan-embed-text-v2:0".freeze

  def self.claude_total_prompt_tokens(usage)
    usage[:input_tokens].to_i + usage[:cache_read_input_tokens].to_i + usage[:cache_write_input_tokens].to_i
  end
end
