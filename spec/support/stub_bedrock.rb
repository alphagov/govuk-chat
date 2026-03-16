module StubBedrock
  TITAN_EMBEDDING_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/.*titan-embed-text.*?/invoke}
  OPENAI_GPT_OSS_ENDPOINT_REGEX = %r{https://bedrock-runtime\..*\.amazonaws\.com/model/openai\.gpt-oss.*?/invoke}

  def stub_bedrock_invoke_model_response(request_body:,
                                         response_body:,
                                         endpoint_regex: TITAN_EMBEDDING_ENDPOINT_REGEX)
    stub_request(:post, endpoint_regex)
      .with(body: request_body)
      .to_return_json(
        status: 200,
        body: response_body,
        headers: { "Content-Type" => "application/json" },
      )
  end

  def stub_bedrock_invoke_model_response_with_error(request_body:, error:)
    stub_request(:post, TITAN_EMBEDDING_ENDPOINT_REGEX)
      .with(body: request_body)
      .to_raise(error)
  end

  def stub_bedrock_titan_invoke_error(input_text, error_message)
    stub_bedrock_invoke_model_response_with_error(
      request_body: { inputText: input_text }.to_json,
      error: Aws::BedrockRuntime::Errors::ValidationException.new({}, error_message),
    )
  end

  def stub_bedrock_titan_embedding(text)
    stub_bedrock_invoke_model_response(
      request_body: { inputText: text }.to_json,
      response_body: bedrock_titan_embedding_response(mock_titan_embedding(text)),
    )
  end

  def bedrock_titan_embedding_response(embedding_array)
    {
      embedding: embedding_array,
    }.to_json
  end

  def mock_titan_embedding(text, dimensions: Search::ChunkedContentRepository::TITAN_EMBEDDING_DIMENSIONS)
    # This returns a mock vector embedding which is deterministic based on the
    # text given
    random_generator = Random.new(text.bytes.sum)
    dimensions.times.map { random_generator.rand }
  end

  def stub_bedrock_invoke_model_openai_oss_tool_call(user_message,
                                                     tools,
                                                     content,
                                                     finish_reason: "tool_calls",
                                                     system_prompt: nil,
                                                     usage: {
                                                       completion_tokens: 35,
                                                       prompt_tokens: 25,
                                                       prompt_tokens_details: {
                                                         cached_tokens: nil, total_tokens: 60
                                                       },
                                                     })
    messages = []
    messages << { role: "system", content: [{ type: "text", text: system_prompt }] } if system_prompt
    messages << { role: "user", content: [{ type: "text", text: user_message }] }

    request_body = {
      include_reasoning: false,
      messages:,
      tools:,
      tool_choice: { type: "function", function: { name: tools.first.dig("function", "name") } },
      parallel_tool_calls: false,
      max_tokens: 15_000,
      temperature: 0.0,
    }.to_json

    response_body = {
      choices: [
        {
          finish_reason:,
          message: {
            tool_calls: [
              {
                type: "function",
                function: {
                  arguments: content,
                },
              },
            ],
          },
        },
      ],
      model: "openai.gpt-oss-120b-1:0",
      usage:,
    }.to_json

    stub_bedrock_invoke_model_response(
      request_body: request_body,
      response_body: response_body,
      endpoint_regex: OPENAI_GPT_OSS_ENDPOINT_REGEX,
    )
  end

  def stub_bedrock_invoke_model_openai_oss_answer_relevancy(question_message:,
                                                            answer_message:,
                                                            statements: ["Statement."],
                                                            verdicts: [{ verdict: "yes" }],
                                                            reason: ["This is the reason for the score."])
    prompts = AutoEvaluation::Prompts.config.answer_relevancy
    stubs = {}

    statements_user_prompt = sprintf(
      prompts.fetch(:statements).fetch(:user_prompt),
      answer: answer_message,
    )
    statements_tools = [prompts.fetch(:statements).fetch(:tool_spec)]
    stubs[:statements] = stub_bedrock_invoke_model_openai_oss_tool_call(
      statements_user_prompt,
      statements_tools,
      { statements: }.to_json,
    )
    return stubs if statements.empty?

    verdicts_user_prompt = sprintf(
      prompts.fetch(:verdicts).fetch(:user_prompt),
      question: question_message,
      statements:,
    )
    verdicts_tools = [prompts.fetch(:verdicts).fetch(:tool_spec)]
    stubs[:verdicts] = stub_bedrock_invoke_model_openai_oss_tool_call(
      verdicts_user_prompt,
      verdicts_tools,
      { verdicts: }.to_json,
    )
    return stubs if verdicts.empty?

    verdicts_count = verdicts.count { |v| v[:verdict].strip.downcase != "no" }
    score = (verdicts_count.to_d / verdicts.count).round(2).to_f
    unsuccessful_verdicts_reasons = verdicts.select { |v| v[:verdict].strip.downcase == "no" }
                                            .map { |v| v[:reason] }

    reason_user_prompt = sprintf(
      prompts.fetch(:reason).fetch(:user_prompt),
      score:,
      unsuccessful_verdicts_reasons:,
      question: question_message,
    )
    reason_tools = [prompts.fetch(:reason).fetch(:tool_spec)]
    stubs[:reason] = stub_bedrock_invoke_model_openai_oss_tool_call(
      reason_user_prompt,
      reason_tools,
      { reason: }.to_json,
    )

    stubs
  end

  def stub_bedrock_invoke_model_openai_oss_faithfulness(retrieval_context:,
                                                        answer_message:,
                                                        truths: ["Truth."],
                                                        claims: ["Claim."],
                                                        verdicts: [{ verdict: "yes" }],
                                                        reason: ["This is the reason for the score."])
    prompts = AutoEvaluation::Prompts.config.faithfulness
    stubs = {}

    truths_user_prompt = sprintf(
      prompts.fetch(:truths).fetch(:user_prompt),
      retrieval_context:,
    )
    truths_tools = [prompts.fetch(:truths).fetch(:tool_spec)]
    stubs[:truths] = stub_bedrock_invoke_model_openai_oss_tool_call(
      truths_user_prompt,
      truths_tools,
      { truths: }.to_json,
    )
    return stubs if truths.empty?

    claims_user_prompt = sprintf(
      prompts.fetch(:claims).fetch(:user_prompt),
      answer: answer_message,
    )
    claims_tools = [prompts.fetch(:claims).fetch(:tool_spec)]
    stubs[:claims] = stub_bedrock_invoke_model_openai_oss_tool_call(
      claims_user_prompt,
      claims_tools,
      { claims: }.to_json,
    )
    return stubs if claims.empty?

    verdicts_user_prompt = sprintf(
      prompts.fetch(:verdicts).fetch(:user_prompt),
      claims:,
      retrieval_context: truths.join("\n\n"),
    )
    verdicts_tools = [prompts.fetch(:verdicts).fetch(:tool_spec)]
    stubs[:verdicts] = stub_bedrock_invoke_model_openai_oss_tool_call(
      verdicts_user_prompt,
      verdicts_tools,
      { verdicts: }.to_json,
    )
    return stubs if verdicts.empty?

    faithful_count = verdicts.count { |v| v[:verdict].strip.downcase != "no" }
    score = (faithful_count.to_d / verdicts.count).round(2).to_f
    contradictions = verdicts.select { |v| v[:verdict].strip.downcase == "no" }
                             .map { |v| v[:reason] }

    reason_user_prompt = sprintf(
      prompts.fetch(:reason).fetch(:user_prompt),
      score:,
      contradictions:,
    )

    reason_tools = [prompts.fetch(:reason).fetch(:tool_spec)]

    stubs[:reason] = stub_bedrock_invoke_model_openai_oss_tool_call(
      reason_user_prompt,
      reason_tools,
      { reason: }.to_json,
    )

    stubs
  end

  def stub_bedrock_invoke_model_openai_oss_context_relevancy(
    question_message:,
    answer_sources: [build(:answer_source)],
    truths: [{ context: "Context", facts: ["Fact."] }],
    information_needs: ["Information need."],
    verdicts: [{ verdict: "yes", reason: "Some reason" }],
    reason: "This is the reason for the score."
  )
    prompts = AutoEvaluation::Prompts.config.context_relevancy
    stubs = {}

    information_needs_user_prompt = sprintf(
      prompts.fetch(:information_needs).fetch(:user_prompt),
      question: question_message,
    )
    information_needs_tools = [prompts.fetch(:information_needs).fetch(:tool_spec)]
    stubs[:information_needs] = stub_bedrock_invoke_model_openai_oss_tool_call(
      information_needs_user_prompt,
      information_needs_tools,
      { information_needs: }.to_json,
    )

    return stubs if information_needs.empty?

    retrieval_context = answer_sources.map do |source|
      <<~CONTEXT
        # Context
        Page title: #{source.title}
        Description: #{source.description}
        Headings: #{source.heading_hierarchy.join(' > ')}
        # Content
        #{Nokogiri::HTML(source.html_content).text}
      CONTEXT
    end

    truths_user_prompt = sprintf(
      prompts.fetch(:truths).fetch(:user_prompt),
      retrieval_context: retrieval_context.join("\n\n"),
    )
    truths_tools = [prompts.fetch(:truths).fetch(:tool_spec)]
    stubs[:truths] = stub_bedrock_invoke_model_openai_oss_tool_call(
      truths_user_prompt,
      truths_tools,
      { truths: }.to_json,
    )
    return stubs if truths.empty?

    formatted_truths = truths.map do |truth|
      <<~TRUTH
        Context: #{truth[:context]}
        Facts:
        #{truth[:facts].join("\n")}
      TRUTH
    end

    verdicts_user_prompt = sprintf(
      prompts.dig(:verdicts, :user_prompt),
      truths: formatted_truths,
      information_needs: information_needs.join("\n"),
    )
    verdicts_tools = [prompts.fetch(:verdicts).fetch(:tool_spec)]
    stubs[:verdicts] = stub_bedrock_invoke_model_openai_oss_tool_call(
      verdicts_user_prompt,
      verdicts_tools,
      { verdicts: }.to_json,
    )
    return stubs if verdicts.empty?

    verdicts_count = verdicts.count { |v| v[:verdict].strip.downcase != "no" }
    score = (verdicts_count.to_d / verdicts.count).round(2).to_f
    unmet_needs = verdicts.select { |v| v[:verdict].strip.downcase == "no" }
                          .map { |v| v[:reason] }

    reason_user_prompt = sprintf(
      prompts.dig(:reason, :user_prompt),
      score:,
      question: question_message,
      unmet_needs: unmet_needs.join("\n"),
    )
    reason_tools = [prompts.fetch(:reason).fetch(:tool_spec)]
    stubs[:reason] = stub_bedrock_invoke_model_openai_oss_tool_call(
      reason_user_prompt,
      reason_tools,
      { reason: }.to_json,
    )

    stubs
  end

  def stub_bedrock_invoke_model_openai_oss_coherence(answer_message:,
                                                     question_message:,
                                                     llm_response: { score: 3, reason: "The reason" })
    prompts = AutoEvaluation::Prompts.config.coherence

    user_prompt = sprintf(
      prompts.fetch(:user_prompt),
      answer: answer_message,
      question: question_message,
    )
    tools = [prompts.fetch(:tool_spec)]

    stub_bedrock_invoke_model_openai_oss_tool_call(
      user_prompt,
      tools,
      llm_response.to_json,
    )
  end

  def stub_bedrock_invoke_model_openai_oss_topic_tagger(user_question,
                                                        llm_response: {
                                                          primary_topic: "business",
                                                          secondary_topic: "benefits",
                                                          reasoning: "reason",
                                                        })
    prompts = AutoEvaluation::Prompts.config.topic_tagger

    system_prompt = prompts.fetch(:system_prompt)
    tools = [prompts.fetch(:tool_spec)]

    stub_bedrock_invoke_model_openai_oss_tool_call(
      user_question,
      tools,
      llm_response.to_json,
      system_prompt:,
      usage: {
        completion_tokens: 35,
        prompt_tokens: 25,
        prompt_tokens_details: { cached_tokens: 10, total_tokens: 60 },
      },
    )
  end
end
