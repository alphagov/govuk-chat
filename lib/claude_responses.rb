module ClaudeResponses
  class MissingContentError < StandardError; end

  def claude_first_text_content(response)
    claude_first_content_by_type(response, :text)
  end

  def claude_first_tool_use(response)
    claude_first_content_by_type(response, :tool_use)
  end

  def claude_total_prompt_tokens(usage)
    usage[:input_tokens].to_i + usage[:cache_read_input_tokens].to_i + usage[:cache_write_input_tokens].to_i
  end

private

  def claude_first_content_by_type(response, type)
    response.content.find { it.type == type } ||
      raise(MissingContentError, "Claude response has no #{type} block (stop_reason: #{response.stop_reason})")
  end
end
