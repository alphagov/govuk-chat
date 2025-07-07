RSpec.describe "User toggles the sources dropdown" do
  scenario "Expanding the dropdown" do
    given_i_am_a_web_chat_user
    and_i_have_an_active_conversation_with_an_answered_question_with_sources
    when_i_visit_the_conversation_page
    and_i_click_on_the_sources_dropdown
    then_the_sources_dropdown_expands
    and_i_see_the_source_links
  end

  scenario "Collapsing the dropdown" do
    given_i_am_a_web_chat_user
    and_i_have_an_active_conversation_with_an_answered_question_with_sources
    when_i_visit_the_conversation_page
    and_i_have_expanded_the_sources_dropdown
    when_i_click_on_the_sources_dropdown_again
    then_the_sources_dropdown_collapses
    and_i_cannot_see_the_source_links
  end

  def and_i_have_an_active_conversation_with_an_answered_question_with_sources
    @conversation = create(:conversation, signon_user: @signon_user)
    set_rack_cookie(:conversation_id, @conversation.id)
    answer = build(:answer, :with_sources, message: "Example answer")
    create(:question, answer:, conversation: @conversation, message: "Example question")
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_click_on_the_sources_dropdown
    # click_on seems to work for links and buttons but not the details element, hence the alternative approach below
    page.find("details", text: "GOV.UK pages used in this answer (links open in a new tab)").click
  end

  def then_the_sources_dropdown_expands
    expect(page).to have_css(".app-c-conversation-sources__details[open]")
  end

  def and_i_see_the_source_links
    expect(page).to have_link(nil, href: "https://www.test.gov.uk/income-tax")
    expect(page).to have_link(nil, href: "https://www.test.gov.uk/vat-tax")
  end

  def and_i_have_expanded_the_sources_dropdown
    page.find("details", text: "GOV.UK pages used in this answer (links open in a new tab)").click
  end

  def when_i_click_on_the_sources_dropdown_again
    page.find("details", text: "GOV.UK pages used in this answer (links open in a new tab)").click
  end

  def then_the_sources_dropdown_collapses
    expect(page).to have_css(".app-c-conversation-sources__details")
    expect(page).not_to have_css(".app-c-conversation-sources__details[open]")
  end

  def and_i_cannot_see_the_source_links
    expect(page).not_to have_link(nil, href: "https://www.test.gov.uk/income-tax")
    expect(page).not_to have_link(nil, href: "https://www.test.gov.uk/vat-tax")
  end
end
