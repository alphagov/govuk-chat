RSpec.describe "Admin user updates settings" do
  scenario do
    given_i_am_an_admin
    and_a_settings_instance_exists

    when_i_visit_the_settings_page
    then_i_should_see_there_are_ten_instant_access_places
    and_i_should_see_there_are_ten_delayed_access_places
    and_i_should_see_the_sign_up_enabled_setting_is_disabled
    and_i_should_see_the_public_access_enabled_setting_is_enabled

    when_i_click_the_edit_link_for_instant_access_places
    and_i_add_five_instant_access_places
    then_i_see_there_are_fifteen_instant_access_places

    when_i_click_the_edit_link_for_delayed_access_places
    and_i_add_five_delayed_access_places
    then_i_see_there_are_fifteen_delayed_access_places

    when_i_click_the_edit_link_for_sign_up_enabled
    and_i_choose_to_enable_signups
    then_i_see_that_signups_are_enabled

    when_i_click_the_edit_link_for_public_access
    and_i_disable_public_access
    then_i_see_that_public_access_is_disabled

    when_i_click_on_the_audits_link
    then_i_can_see_the_audits_for_my_changes
  end

  def and_a_settings_instance_exists
    create(
      :settings,
      public_access_enabled: true,
      downtime_type: "temporary",
      instant_access_places: 10,
      delayed_access_places: 10,
      sign_up_enabled: false,
    )
  end

  def when_i_visit_the_settings_page
    visit admin_settings_path
  end

  def then_i_should_see_there_are_ten_instant_access_places
    expect(page).to have_selector(".govuk-summary-list__row", text: "Available instant access places 10")
  end

  def and_i_should_see_there_are_ten_delayed_access_places
    expect(page).to have_selector(".govuk-summary-list__row", text: "Available delayed access places 10")
  end

  def and_i_should_see_the_sign_up_enabled_setting_is_disabled
    within("#sign-up-enabled") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled No")
    end
  end

  def and_i_should_see_the_public_access_enabled_setting_is_enabled
    within("#public-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled Yes")
    end
  end

  def when_i_click_the_edit_link_for_instant_access_places
    click_on "Edit Available instant access places"
  end

  def and_i_add_five_instant_access_places
    fill_in "Additional places", with: 5
    click_on "Submit"
  end
  alias_method :and_i_add_five_delayed_access_places, :and_i_add_five_instant_access_places

  def then_i_see_there_are_fifteen_instant_access_places
    expect(page).to have_selector(".govuk-summary-list__row", text: "Available instant access places 15")
  end

  def when_i_click_the_edit_link_for_delayed_access_places
    click_on "Edit Available delayed access places"
  end

  def then_i_see_there_are_fifteen_delayed_access_places
    expect(page).to have_selector(".govuk-summary-list__row", text: "Available delayed access places 15")
  end

  def when_i_click_the_edit_link_for_sign_up_enabled
    within("#sign-up-enabled") { click_on "Edit Enabled" }
  end

  def and_i_choose_to_enable_signups
    choose "Yes"
    click_on "Submit"
  end

  def then_i_see_that_signups_are_enabled
    within("#sign-up-enabled") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled Yes")
    end
  end

  def when_i_click_the_edit_link_for_public_access
    within("#public-access") { click_on "Edit Enabled" }
  end

  def and_i_disable_public_access
    choose "No"
    choose "Permanent"
    click_on "Submit"
  end

  def then_i_see_that_public_access_is_disabled
    within("#public-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled No - permanently offline")
    end
  end

  def when_i_click_on_the_audits_link
    click_on "Audits"
  end

  def then_i_can_see_the_audits_for_my_changes
    expect(page)
      .to have_content("Added 5 instant access places")
      .and have_content("Added 5 delayed access places")
      .and have_content("Sign up enabled set to true")
      .and have_content("Public access enabled set to false, downtime type permanent")
  end
end
