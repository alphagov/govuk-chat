RSpec.describe "Admin user searches and views chunks", :chunked_content_index do
  scenario do
    given_i_am_an_admin
    and_there_is_a_pax_my_tax_chunk_to_find
    when_i_visit_the_admin_area
    and_i_browse_to_the_search_section
    and_i_search_for_pay_my_tax
    then_i_should_see_search_results
    when_i_click_on_a_search_result
    then_i_see_details_of_the_chunk
    when_i_click_the_back_button
    then_the_search_page_has_the_correct_search_term
  end

  def given_i_am_an_admin
    login_as(create(:admin_user, :admin))
  end

  def and_there_is_a_pax_my_tax_chunk_to_find
    openai_embedding = mock_openai_embedding("how to pay tax")
    stub_openai_embedding("how to pay tax")
    chunk = build(:chunked_content_record,
                  title: "How to pay your tax",
                  openai_embedding:)
    populate_chunked_content_index([chunk])
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_search_section
    click_link "Search"
  end

  def and_i_search_for_pay_my_tax
    fill_in "Text to search for", with: "how to pay tax"
    click_button "Search"
  end

  def then_i_should_see_search_results
    expect(page).to have_selector("a", text: "How to pay your tax")
  end

  def when_i_click_on_a_search_result
    click_link "How to pay your tax"
  end

  def then_i_see_details_of_the_chunk
    expect(page).to have_content("Chunk details: How to pay your tax")
  end

  def when_i_click_the_back_button
    click_link "Back to results"
  end

  def then_the_search_page_has_the_correct_search_term
    expect(page).to have_selector("input[name='search_text'][value='how to pay tax']")
    expect(page).to have_selector("a", text: "How to pay your tax")
  end
end
