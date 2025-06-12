module BedrockModels
  CLAUDE_SONNET = ENV.fetch("CLAUDE_SONNET_MODEL_ID", "eu.anthropic.claude-3-7-sonnet-20250219-v1:0").freeze
  TITAN_EMBED_V2 = "amazon.titan-embed-text-v2:0".freeze
end
