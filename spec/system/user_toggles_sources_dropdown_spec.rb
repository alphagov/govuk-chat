RSpec.describe "User toggles the sources dropdown" do
  scenario do
    given_i_am_a_web_chat_user
    and_i_have_an_active_conversation_with_an_answered_question_with_sources
    when_i_visit_the_conversation_page
    then_i_cannot_see_the_source_links

    when_i_click_on_the_sources_dropdown
    then_i_can_see_the_source_links

    when_i_click_on_the_sources_dropdown_again
    then_i_cannot_see_the_source_links
  end

  def and_i_have_an_active_conversation_with_an_answered_question_with_sources
    @conversation = create(:conversation, signon_user: @signon_user)
    set_rack_cookie(:conversation_id, @conversation.id)
    @source_vat = build(:answer_source, exact_path: "/vat", title: "Everything about VAT", relevancy: 0)
    @source_income_tax = build(:answer_source, exact_path: "/income-tax", title: "Income Tax Details", relevancy: 1)
    answer = build(:answer, sources: [@source_vat, @source_income_tax], message: "Example answer")
    create(:question, answer:, conversation: @conversation, message: "Example question")
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def then_i_cannot_see_the_source_links
    expect(page).not_to have_link(@source_vat.title, href: @source_vat.url)
    expect(page).not_to have_link(@source_income_tax.title, href: @source_income_tax.url)
  end

  def when_i_click_on_the_sources_dropdown
    # click_on seems to work for links and buttons but not the details element, hence the alternative approach below
    page.find("details", text: "GOV.UK pages used in this answer (links open in a new tab)").click
  end
  alias_method :when_i_click_on_the_sources_dropdown_again, :when_i_click_on_the_sources_dropdown

  def then_i_can_see_the_source_links
    expect(page).to have_link(@source_vat.title, href: @source_vat.url)
    expect(page).to have_link(@source_income_tax.title, href: @source_income_tax.url)
  end
end
