RSpec.describe "Conversation with OpenAI", :chunked_content_index do
  include ActiveJob::TestHelper

  around do |example|
    ClimateControl.modify(
      OPENAI_ACCESS_TOKEN: "real-open-ai-access-token",
    ) do
      example.run
    end
  end

  before do
    stub_open_ai_flag_active
    stub_text_to_embedding
    populate_opensearch
  end

  scenario do
    given_i_have_confirmed_i_understand_chat_risks
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

  def stub_open_ai_flag_active
    Flipper.enable_actor(:open_ai, AnonymousUser.new("known-user"))
  end

  def stub_text_to_embedding
    @openai_embedding = mock_openai_embedding("How much tax should i pay?")
    allow(Search::TextToEmbedding)
    .to receive(:call)
    .and_return(@openai_embedding)
  end

  def populate_opensearch
    populate_chunked_content_index([
      build(:chunked_content_record, openai_embedding: @openai_embedding),
    ])
  end

  def when_i_visit_the_conversation_page
    visit "/chat/conversations?user_id=known-user"
  end

  def and_i_enter_a_question
    fill_in "Enter a question", with: "How much tax should I be paying?"
    click_on "Submit"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_first_answer_is_generated
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => "How much tax should I be paying?" }),
      "First answer from OpenAI",
    )

    perform_enqueued_jobs
  end

  def when_the_second_answer_is_generated
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => "Are you sure?" }),
      "Rephrased How much tax should I be paying?",
    )
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => "Rephrased How much tax should I be paying?" }),
      "Second answer from OpenAI",
    )
    perform_enqueued_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content("First answer from OpenAI")
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content("Second answer from OpenAI")
  end

  def when_i_enter_a_second_question
    fill_in "Enter a question", with: "Are you sure?"
    click_on "Submit"
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content("Are you sure?")
  end
end
