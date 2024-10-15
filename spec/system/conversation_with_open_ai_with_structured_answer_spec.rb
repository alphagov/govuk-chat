RSpec.describe "Conversation with OpenAI with a structured answer", :chunked_content_index do
  scenario do
    given_i_am_a_signed_in_early_access_user
    and_i_have_confirmed_i_understand_chat_risks
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
    fill_in "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)", with: @first_question
    click_on "Send"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_first_answer_is_generated
    openai_embedding = mock_openai_embedding(@first_question)
    allow(Search::TextToEmbedding)
      .to receive(:call)
      .and_return(openai_embedding)
    populate_chunked_content_index([
      build(:chunked_content_record, openai_embedding:, exact_path: "/pay-more-tax#yes-really"),
    ])

    stub_openai_jailbreak_guardrails(@first_question)
    stub_openai_chat_question_routing(@first_question)
    stub_openai_chat_completion_structured_response(
      @first_question,
      {
        answer: "Lots of tax.",
        answered: true,
        sources_used: ["/pay-more-tax#yes-really"],
      }.to_json,
    )
    stub_openai_output_guardrail("Lots of tax.")

    execute_queued_sidekiq_jobs
  end

  def when_the_second_answer_is_generated
    rephrased_question = "Rephrased How much tax should I be paying?"

    stub_openai_jailbreak_guardrails(@second_question)
    stub_openai_question_rephrasing(@second_question, rephrased_question)
    stub_openai_chat_question_routing(rephrased_question)
    stub_openai_chat_completion_structured_response(
      rephrased_question,
      {
        answer: "Even more tax.",
        answered: true,
        sources_used: ["/pay-more-tax#yes-really"],
      }.to_json,
    )
    stub_openai_output_guardrail("Even more tax.")

    execute_queued_sidekiq_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content(@first_question)
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content("Lots of tax.")
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content("Even more tax.")
  end

  def when_i_enter_a_second_question
    @second_question = "Are you sure?"
    fill_in "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)", with: @second_question
    click_on "Send"
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content(@second_question)
  end
end
