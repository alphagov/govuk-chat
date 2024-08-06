RSpec.describe "Admin user updates settings" do
  scenario do
    given_i_am_an_admin
    and_a_settings_instance_exists

    when_i_visit_the_settings_page
    then_i_should_see_there_are_ten_instant_access_places
    and_i_should_see_the_sign_up_enabled_setting_is_disabled

    when_i_click_the_edit_link_for_instant_access_places
    and_i_add_five_instant_access_places
    then_i_see_there_are_fifteen_instant_access_places

    when_i_click_the_edit_link_for_sign_up_enabled
    and_i_choose_to_enable_signups
    then_i_see_that_signups_are_enabled
  end

  def and_a_settings_instance_exists
    create(
      :settings,
      instant_access_places: 10,
      sign_up_enabled: false,
    )
  end

  def when_i_visit_the_settings_page
    visit admin_settings_path
  end

  def then_i_should_see_there_are_ten_instant_access_places
    expect(page).to have_selector(".govuk-summary-list__row", text: "Available instant access places 10")
  end

  def and_i_should_see_the_sign_up_enabled_setting_is_disabled
    expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled No")
  end

  def when_i_click_the_edit_link_for_instant_access_places
    click_on "Edit Available instant access places"
  end

  def and_i_add_five_instant_access_places
    fill_in "Additional places", with: 5
    click_on "Submit"
  end

  def then_i_see_there_are_fifteen_instant_access_places
    expect(page).to have_selector(".govuk-summary-list__row", text: "Available instant access places 15")
  end

  def when_i_click_the_edit_link_for_sign_up_enabled
    click_on "Edit Enabled"
  end

  def and_i_choose_to_enable_signups
    choose "Yes"
    click_on "Submit"
  end

  def then_i_see_that_signups_are_enabled
    expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled Yes")
  end
end
