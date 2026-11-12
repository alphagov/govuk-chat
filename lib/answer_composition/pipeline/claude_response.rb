module AnswerComposition::Pipeline
  module ClaudeResponse
    class UnexpectedResponseError < StandardError; end

    def self.content_block(response, type)
      if response.stop_reason == :refusal
        raise UnexpectedResponseError, "Claude refused to respond"
      end

      response.content.find { it.type == type } ||
        raise(UnexpectedResponseError, "Claude response has no #{type} block (stop_reason: #{response.stop_reason})")
    end
  end
end
