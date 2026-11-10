module StubClaudeMessages
  CLAUDE_SONNET_4_5_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*eu.anthropic.claude-sonnet-4-5-20250929-v1:0.*?/invoke}
  CLAUDE_HAIKU_4_5_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*anthropic\.claude-haiku-4-5-20251001-v1:0.*?/invoke}
  CLAUDE_SONNET_5_5_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*eu\.anthropic\.claude-sonnet-5-5/invoke}
  CLAUDE_HAIKU_5_5_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*eu\.anthropic\.claude-haiku-5-5/invoke}

  def stub_claude_messages_response(question_or_history,
                                    content:,
                                    system: nil,
                                    stop_reason: :end_turn,
                                    usage: {},
                                    with_thinking_block: false,
                                    chat_options: {})
    history = if question_or_history.is_a?(String) || question_or_history.is_a?(Regexp)
                array_including({ "role" => "user", "content" => question_or_history })
              else
                question_or_history
              end

    bedrock_model = chat_options.delete(:bedrock_model) || :claude_sonnet_4_5
    chat_options = claude_default_chat_options(bedrock_model).merge(chat_options).compact

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

    content = [claude_messages_thinking_block, *content] if with_thinking_block

    response = claude_messages_response(
      content:,
      usage:,
      stop_reason:,
      bedrock_model:,
    )

    endpoint_regex = case bedrock_model
                     when :claude_sonnet_4_5
                       CLAUDE_SONNET_4_5_ENDPOINT_REGEX
                     when :claude_haiku_4_5
                       CLAUDE_HAIKU_4_5_ENDPOINT_REGEX
                     when :claude_sonnet_5_5
                       CLAUDE_SONNET_5_5_ENDPOINT_REGEX
                     when :claude_haiku_5_5
                       CLAUDE_HAIKU_5_5_ENDPOINT_REGEX
                     end

    # The 5.5 models reject `temperature`, so check we don't send it at all.
    sends_temperature_allowed = %i[claude_sonnet_4_5 claude_haiku_4_5].include?(bedrock_model)

    stub_request(:post, endpoint_regex)
      .with(body: hash_including(matchers)) { |request| sends_temperature_allowed || !JSON.parse(request.body).key?("temperature") }
      .to_return_json(
        status: 200,
        body: response,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_claude_jailbreak_guardrails(input,
                                       response = "PassValue",
                                       with_thinking_block: false,
                                       chat_options: { bedrock_model: AnswerComposition::Pipeline::JailbreakGuardrails::DEFAULT_MODEL })
    jailbreak_guardrails_config = Rails.configuration
                                       .govuk_chat_private
                                       .llm_prompts
                                       .answer_composition
                                       .jailbreak_guardrails

    model_config = jailbreak_guardrails_config[chat_options[:bedrock_model]]

    allow(model_config).to receive(:fetch).and_call_original
    allow(model_config).to receive(:fetch).with(:pass_value).and_return("PassValue")
    allow(model_config).to receive(:fetch).with(:fail_value).and_return("FailValue")

    stub_claude_messages_response(
      input,
      content: [claude_messages_text_block(response)],
      with_thinking_block:,
      chat_options: { max_tokens: model_config.fetch(:max_tokens) }.merge(chat_options),
    )
  end

  def stub_claude_question_rephrasing(original_question,
                                      rephrased_question,
                                      with_thinking_block: false,
                                      chat_options: { bedrock_model: AnswerComposition::Pipeline::QuestionRephraser::DEFAULT_MODEL })
    stub_claude_messages_response(
      array_including({ "role" => "user", "content" => a_string_including(original_question) }),
      content: [claude_messages_text_block(rephrased_question)],
      with_thinking_block:,
      chat_options: chat_options,
    )
  end

  def stub_claude_question_routing(question_or_history,
                                   tools: an_instance_of(Array),
                                   tool_name: "genuine_rag",
                                   tool_input: { "answer": "This is RAG.", confidence: 1.0 },
                                   stop_reason: :tool_use,
                                   with_thinking_block: false,
                                   chat_options: { bedrock_model: AnswerComposition::Pipeline::QuestionRouter::DEFAULT_MODEL })
    tool_choice_type = chat_options[:bedrock_model] == :claude_sonnet_4_5 ? "any" : "auto"
    chat_options = {
      tools:,
      tool_choice: { type: tool_choice_type, disable_parallel_tool_use: true },
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
      with_thinking_block:,
      chat_options:,
    )
  end

  def stub_claude_structured_answer(question_or_history,
                                    answer,
                                    sources_used: %w[link_1],
                                    answer_completeness: "complete",
                                    with_thinking_block: false,
                                    chat_options: { bedrock_model: AnswerComposition::Pipeline::StructuredAnswerComposer::DEFAULT_MODEL })
    model = chat_options[:bedrock_model]
    tools = Rails.configuration
                 .govuk_chat_private
                 .llm_prompts
                 .answer_composition[:structured_answer][model][:tool_spec]

    allow(Rails.configuration.govuk_chat_private.llm_prompts.answer_composition.structured_answer)
      .to receive(:fetch)
      .with(model)
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
    }.merge(chat_options)

    system = array_including(
      { "type" => "text", "text" => "Static portion", "cache_control" => { "type" => "ephemeral" } },
      { "type" => "text", "text" => "Dynamic portion" },
    )

    stub_claude_messages_response(
      question_or_history,
      content: [claude_messages_tool_use_block(
        input: { answer:, sources_used:, answer_completeness: },
        name: "output_schema",
      )],
      system:,
      stop_reason: :tool_use,
      usage: { cache_read_input_tokens: 20 },
      with_thinking_block:,
      chat_options:,
    )
  end

  def stub_claude_output_guardrails(to_check,
                                    response = [].to_json,
                                    stop_reason: :end_turn,
                                    with_thinking_block: false,
                                    chat_options: { bedrock_model: AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL })
    system = array_including(a_hash_including("cache_control" => { "type" => "ephemeral" }))

    output_config = { "format" => a_hash_including("type" => "json_schema") }
    output_config["effort"] = "low" unless chat_options[:bedrock_model] == :claude_haiku_4_5
    chat_options[:output_config] = a_hash_including(output_config)

    stub_claude_messages_response(
      array_including({ "role" => "user", "content" => a_string_including(to_check) }),
      content: [claude_messages_text_block(response)],
      system:,
      stop_reason:,
      usage: { cache_read_input_tokens: 20 },
      with_thinking_block:,
      chat_options: {
        temperature: nil,
        max_tokens: AnswerComposition::MultipleGuardrail::Checker::MAX_TOKENS,
      }.merge(chat_options),
    )
  end

  def claude_default_chat_options(bedrock_model)
    case bedrock_model
    when :claude_sonnet_4_5, :claude_haiku_4_5
      { temperature: 0.0, max_tokens: 4096 }
    when :claude_sonnet_5_5
      { max_tokens: 4096, thinking: { type: "between_tools" }, output_config: { effort: "low" } }
    when :claude_haiku_5_5
      { max_tokens: 4096, thinking: { type: "disabled" }, output_config: { effort: "low" } }
    end
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

  def claude_messages_thinking_block
    Anthropic::Models::ThinkingBlock.new(
      type: :thinking,
      thinking: "",
      signature: "thinking-signature",
    )
  end

  def claude_messages_usage_block(input_tokens: 10, output_tokens: 20, cache_read_input_tokens: nil)
    Anthropic::Models::Usage.new(
      input_tokens:,
      output_tokens:,
      cache_read_input_tokens:,
    )
  end

  def claude_messages_response(content:, bedrock_model:, usage: {}, stop_reason: :end_turn)
    Anthropic::Models::Message.new(
      id: "msg-id",
      model: BedrockModels.model_id(bedrock_model),
      role: :assistant,
      content:,
      stop_reason:,
      usage: claude_messages_usage_block(**usage),
      type: :message,
    )
  end
end
