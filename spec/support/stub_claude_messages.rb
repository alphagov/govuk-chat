module StubClaudeMessages
  CLAUDE_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*anthropic\.claude.*?/invoke}

  def stub_claude_messages_response(question_or_history,
                                    content:,
                                    stop_reason: :end_turn,
                                    usage: {},
                                    chat_options: {})
    history = if question_or_history.is_a?(String) || question_or_history.is_a?(Regexp)
                array_including({ "role" => "user", "content" => question_or_history })
              else
                question_or_history
              end

    chat_options = { temperature: 0.0, max_tokens: 4096 }.merge(chat_options).compact

    request_body = hash_including(
      messages: history,
      **chat_options,
    )

    response = Anthropic::Models::Message.new(
      id: "msg-id",
      model: BedrockModels::CLAUDE_SONNET,
      role: :assistant,
      content:,
      stop_reason:,
      usage: claude_messages_usage_block(**usage),
      type: :message,
    )

    stub_request(:post, CLAUDE_ENDPOINT_REGEX)
      .with(body: request_body)
      .to_return_json(
        status: 200,
        body: response,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_claude_jailbreak_guardrails(input, triggered: false)
    llm_prompts_config = Rails.configuration.govuk_chat_private.llm_prompts
    allow(llm_prompts_config.common).to receive(:jailbreak_guardrails).and_return(pass_value: "PassValue")
    allow(llm_prompts_config.claude.jailbreak_guardrails)
      .to receive(:fetch)
      .with(:max_tokens)
      .and_return(20)

    answer = triggered ? "FailValue" : "PassValue"

    stub_claude_messages_response(
      input,
      content: [claude_messages_text_block(answer)],
      chat_options: { max_tokens: 20 },
    )
  end

  def stub_claude_question_rephrasing(original_question, rephrased_question)
    stub_claude_messages_response(
      array_including({ "role" => "user", "content" => a_string_including(original_question) }),
      content: [claude_messages_text_block(rephrased_question)],
    )
  end

  def claude_messages_text_block(text)
    Anthropic::Models::TextBlock.new(
      type: :text,
      text:,
    )
  end

  def claude_messages_usage_block(input_tokens: 10, output_tokens: 20, cache_read_input_tokens: 20)
    Anthropic::Models::Usage.new(
      input_tokens:,
      output_tokens:,
      cache_read_input_tokens:,
    )
  end
end
