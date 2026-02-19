module StubClaudeMessages
  CLAUDE_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*anthropic\.claude.*?/invoke}

  def stub_claude_messages_response(question_or_history,
                                    content:,
                                    system: nil,
                                    stop_reason: :end_turn,
                                    usage: {},
                                    chat_options: {})
    history = if question_or_history.is_a?(String) || question_or_history.is_a?(Regexp)
                array_including({ "role" => "user", "content" => question_or_history })
              else
                question_or_history
              end

    chat_options = { temperature: 0.0, max_tokens: 4096 }.merge(chat_options).compact

    matchers = {
      messages: history,
      **chat_options,
    }

    if system.is_a?(String) || system.is_a?(Regexp)
      matchers[:system] = array_including(
        a_hash_including(
          "type" => "text",
          "text" => system,
        ),
      )
    elsif system.present?
      matchers[:system] = system
    end

    response = claude_messages_response(
      content:,
      usage:,
      stop_reason:,
    )

    stub_request(:post, CLAUDE_ENDPOINT_REGEX)
      .with(body: hash_including(matchers))
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

  def stub_claude_question_routing(question_or_history,
                                   tools: an_instance_of(Array),
                                   tool_name: "genuine_rag",
                                   tool_input: { "answer": "This is RAG.", confidence: 1.0 },
                                   stop_reason: :tool_use,
                                   chat_options: {})
    chat_options = {
      tools:,
      tool_choice: { type: "any", disable_parallel_tool_use: true },
      max_tokens: 500,
    }.merge(chat_options)

    system = array_including(a_hash_including("cache_control" => { "type" => "ephemeral" }))

    stub_claude_messages_response(
      question_or_history,
      content: [claude_messages_tool_use_block(
        input: tool_input,
        name: tool_name,
      )],
      system:,
      stop_reason:,
      usage: { cache_read_input_tokens: 20 },
      chat_options:,
    )
  end

  def stub_claude_structured_answer(question_or_history,
                                    answer,
                                    answered: true,
                                    sources_used: %w[link_1],
                                    answer_completeness: "complete")
    tools = Rails.configuration
                 .govuk_chat_private
                 .llm_prompts
                 .claude[:structured_answer][:tool_spec]

    allow(Rails.configuration.govuk_chat_private.llm_prompts.claude)
      .to receive(:structured_answer)
      .and_return(
        {
          cached_system_prompt: "Static portion",
          context_system_prompt: "Dynamic portion",
          tool_spec: tools,
        },
      )

    chat_options = {
      tools: [tools],
      tool_choice: { type: "tool", name: "output_schema" },
    }

    system = array_including(
      { "type" => "text", "text" => "Static portion", "cache_control" => { "type" => "ephemeral" } },
      { "type" => "text", "text" => "Dynamic portion" },
    )

    stub_claude_messages_response(
      question_or_history,
      content: [claude_messages_tool_use_block(
        input: { answer:, answered:, sources_used:, answer_completeness: },
        name: "output_schema",
      )],
      system:,
      stop_reason: :tool_use,
      usage: { cache_read_input_tokens: 20 },
      chat_options:,
    )
  end

  def stub_claude_output_guardrails(to_check, response = "False | None")
    system = array_including(a_hash_including("cache_control" => { "type" => "ephemeral" }))

    stub_claude_messages_response(
      array_including({ "role" => "user", "content" => a_string_including(to_check) }),
      content: [claude_messages_text_block(response)],
      system:,
      usage: { cache_read_input_tokens: 20 },
      chat_options: { temperature: nil, max_tokens: Guardrails::Claude::MultipleChecker::MAX_TOKENS },
    )
  end

  def stub_claude_messages_topic_tagger(message)
    topic_tagger_config = Rails.configuration.govuk_chat_private.llm_prompts.claude.topic_tagger
    system = array_including(
      { "type" => "text", "text" => topic_tagger_config["system_prompt"], "cache_control" => { "type" => "ephemeral" } },
    )
    tools = [topic_tagger_config["tool_spec"]]
    content = [
      claude_messages_tool_use_block(
        input: { primary_topic: "business", secondary_topic: "benefits", reasoning: "reason" },
        name: tools.first["name"],
      ),
    ]

    chat_options = {
      tools:,
      tool_choice: { type: "tool", name: tools.first["name"] },
    }

    stub_claude_messages_response(
      message,
      content:,
      system:,
      usage: { cache_read_input_tokens: 20 },
      stop_reason: :tool_use,
      chat_options:,
    )
  end

  def claude_messages_tool_use_block(input:, name:, id: "tool-use-id")
    Anthropic::Models::ToolUseBlock.new(
      id:,
      name:,
      input:,
      type: :tool_use,
    )
  end

  def claude_messages_text_block(text)
    Anthropic::Models::TextBlock.new(
      type: :text,
      text:,
    )
  end

  def claude_messages_usage_block(input_tokens: 10, output_tokens: 20, cache_read_input_tokens: nil)
    Anthropic::Models::Usage.new(
      input_tokens:,
      output_tokens:,
      cache_read_input_tokens:,
    )
  end

  def claude_messages_response(content:, usage: {}, stop_reason: :end_turn)
    Anthropic::Models::Message.new(
      id: "msg-id",
      model: BedrockModels.model_id(:claude_sonnet_4_0),
      role: :assistant,
      content:,
      stop_reason:,
      usage: claude_messages_usage_block(**usage),
      type: :message,
    )
  end
end
