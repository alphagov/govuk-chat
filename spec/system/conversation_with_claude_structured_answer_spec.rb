RSpec.describe "Conversation with Claude with a structured answer", :aws_credentials_stubbed, :chunked_content_index do
  scenario do
    given_i_am_using_the_claude_structured_answer_strategy

    when_i_visit_the_conversation_page
    and_i_enter_a_question
    then_i_see_the_answer_is_pending

    when_the_first_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_question_on_the_page
    and_i_can_see_the_first_answer

    when_i_enter_a_second_question
    then_i_see_the_answer_is_pending

    when_the_second_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_second_question_on_the_page
    and_i_can_see_the_second_answer
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_enter_a_question
    @first_question = "How much tax should I be paying?"
    fill_in "Message", with: @first_question
    click_on "Send"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_first_answer_is_generated
    titan_embedding = mock_titan_embedding(@first_question)
    allow(Search::TextToEmbedding)
      .to receive(:call)
      .and_return(titan_embedding)

    populate_chunked_content_index([
      build(:chunked_content_record, titan_embedding:, exact_path: "/pay-more-tax#yes-really"),
    ])

    @first_answer = "Lots of tax."

    stub_claude_jailbreak_guardrails(@first_question, triggered: false)
    stub_claude_question_routing(@first_question)
    stub_claude_structured_answer(@first_question, @first_answer)
    stub_claude_output_guardrails(@first_answer, "False | None")
    stub_claude_messages_topic_tagger(@first_question)
    stub_bedrock_invoke_model_openai_oss_answer_relevancy(
      question_message: @first_question,
      answer_message: @first_answer,
    )
    stub_bedrock_invoke_model_openai_oss_coherence(
      question_message: @first_question,
      answer_message: @first_answer,
    )

    execute_queued_sidekiq_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content(@first_question)
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content(@first_answer)
  end

  def when_i_enter_a_second_question
    @second_question = "Are you sure?"
    fill_in "Message", with: @second_question
    click_on "Send"
  end

  def when_the_second_answer_is_generated
    rephrased_question = "Rephrased #{@second_question}"
    @second_answer = "Even more tax."

    stub_claude_jailbreak_guardrails(@second_question, triggered: false)
    stub_claude_question_rephrasing(@second_question, rephrased_question)
    stub_claude_question_routing(rephrased_question)
    stub_claude_structured_answer(rephrased_question, @second_answer)
    stub_claude_output_guardrails(@second_answer, "False | None")
    stub_claude_messages_topic_tagger(rephrased_question)
    stub_bedrock_invoke_model_openai_oss_answer_relevancy(
      question_message: rephrased_question,
      answer_message: @second_answer,
    )
    stub_bedrock_invoke_model_openai_oss_coherence(
      question_message: rephrased_question,
      answer_message: @second_answer,
    )

    execute_queued_sidekiq_jobs
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content(@second_question)
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content(@second_answer)
  end
end
