module StubAnthropic
  ANTHROPIC_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*anthropic\.claude.*?/invoke}

  def stub_anthropic_post(question_or_history, response, max_tokens:, chat_options: {})
    history = if question_or_history.is_a?(String) || question_or_history.is_a?(Regexp)
                array_including({ "role" => "user", "content" => question_or_history })
              else
                question_or_history
              end

    chat_options = { temperature: 0.0 }.merge(chat_options)

    request_body = hash_including(
      messages: history,
      max_tokens:,
      **chat_options,
    )

    stub_request(:post, ANTHROPIC_ENDPOINT_REGEX)
      .with(body: request_body)
      .to_return_json(
        status: 200,
        body: response,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_anthropic_claude_response(question_or_history,
                                     content:,
                                     stop_reason: :end_turn,
                                     input_tokens: 10,
                                     output_tokens: 20,
                                     cache_read_input_tokens: nil,
                                     max_tokens: 4096,
                                     chat_options: {})
    usage = Anthropic::Models::Usage.new(
      input_tokens:,
      output_tokens:,
      cache_read_input_tokens:,
    )

    response = Anthropic::Models::Message.new(
      id: "msg-id",
      model: BedrockModels::CLAUDE_SONNET,
      role: :assistant,
      content:,
      stop_reason:,
      usage:,
      type: :message,
    )

    stub_anthropic_post(question_or_history, response, max_tokens:, chat_options:)
  end

  def stub_anthropic_claude_tool_response(question_or_history,
                                          tool_input:,
                                          tool_name: "output_schema",
                                          tool_use_id: "tool-use-id",
                                          input_tokens: 10,
                                          output_tokens: 20,
                                          cache_read_input_tokens: 20,
                                          stop_reason: :tool_use,
                                          max_tokens: 4096,
                                          chat_options: {})
    tool_use_block = Anthropic::Models::ToolUseBlock.new(
      id: tool_use_id,
      name: tool_name,
      input: tool_input,
      type: :tool_use,
    )

    stub_anthropic_claude_response(
      question_or_history,
      content: [tool_use_block],
      stop_reason:,
      input_tokens:,
      output_tokens:,
      cache_read_input_tokens:,
      max_tokens:,
      chat_options:,
    )
  end

  def stub_anthropic_claude_structured_answer_response(question_or_history, answer, answered: true)
    tools = Rails.configuration
                 .govuk_chat_private
                 .llm_prompts
                 .claude[:structured_answer][:tool_spec]

    chat_options = {
      tools: [tools],
      tool_choice: { type: "tool", name: "output_schema" },
    }

    stub_anthropic_claude_tool_response(
      question_or_history,
      tool_input: { answer:, answered:, sources_used: %w[link_1] },
      tool_name: "output_schema",
      chat_options:,
    )
  end

  def stub_anthropic_claude_text_response(question_or_history,
                                          answer: nil,
                                          input_tokens: 10,
                                          output_tokens: 20,
                                          cache_read_input_tokens: nil,
                                          stop_reason: :end_turn,
                                          max_tokens: 4096,
                                          chat_options: {})
    text_block = Anthropic::Models::TextBlock.new(
      type: :text,
      text: answer,
    )

    stub_anthropic_claude_response(
      question_or_history,
      content: [text_block],
      stop_reason:,
      input_tokens:,
      output_tokens:,
      cache_read_input_tokens:,
      max_tokens:,
      chat_options:,
    )
  end

  def stub_anthropic_claude_jailbreak_guardrails_response(input, triggered: false)
    llm_prompts_config = Rails.configuration.govuk_chat_private.llm_prompts
    allow(llm_prompts_config.common).to receive(:jailbreak_guardrails).and_return(pass_value: "PassValue")
    allow(llm_prompts_config.claude.jailbreak_guardrails)
      .to receive(:fetch)
      .with(:max_tokens)
      .and_return(20)

    answer = triggered ? "FailValue" : "PassValue"

    stub_anthropic_claude_text_response(input, answer:, max_tokens: 20)
  end

  def stub_anthropic_question_rephrasing(original_question, rephrased_question)
    history = array_including(
      { "role" => "user", "content" => a_string_including(original_question) },
    )

    stub_anthropic_claude_text_response(
      history,
      answer: rephrased_question,
    )
  end

  def stub_anthropic_claude_question_routing(question_or_history,
                                             tools: an_instance_of(Array),
                                             tool_name: "genuine_rag",
                                             tool_input: { "answer": "This is RAG.", confidence: 1.0 },
                                             stop_reason: :tool_use,
                                             max_tokens: 160)
    chat_options = {
      tools:,
      tool_choice: { type: "any" },
    }

    stub_anthropic_claude_tool_response(
      question_or_history,
      tool_input:,
      tool_name:,
      stop_reason:,
      max_tokens:,
      chat_options:,
    )
  end

  def stub_anthropic_guardrails(to_check, response = "False | None")
    stub_anthropic_claude_text_response(
      array_including({ "role" => "user", "content" => a_string_including(to_check) }),
      answer: response,
      max_tokens: Guardrails::Claude::MultipleChecker::MAX_TOKENS,
      cache_read_input_tokens: 20,
      chat_options: { temperature: nil },
    )
  end
end
