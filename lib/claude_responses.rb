module ClaudeResponses
  def claude_total_prompt_tokens(usage)
    usage[:input_tokens].to_i + usage[:cache_read_input_tokens].to_i + usage[:cache_write_input_tokens].to_i
  end
end
