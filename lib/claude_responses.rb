module ClaudeResponses
  def claude_total_prompt_tokens(usage)
    usage[:input_tokens].to_i + usage[:cache_read_input_tokens].to_i + usage[:cache_creation_input_tokens].to_i
  end
end
