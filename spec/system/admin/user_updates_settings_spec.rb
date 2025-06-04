RSpec.describe "Admin user updates settings" do
  scenario do
    given_i_am_an_admin
    and_a_settings_instance_exists

    when_i_visit_the_settings_page
    and_i_should_see_the_public_access_enabled_setting_is_enabled
    and_i_should_see_the_waiting_list_promotions_per_run_setting_is_twenty_five
    and_i_should_see_the_max_waiting_list_places_setting_is_ten

    when_i_click_the_edit_link_for_public_access
    and_i_disable_public_access
    then_i_see_that_public_access_is_disabled

    when_i_click_the_edit_link_for_waiting_list_promotions_per_run
    and_i_set_the_waiting_list_promotions_per_run_to_fifty
    and_i_should_see_the_waiting_list_promotions_per_run_setting_is_fifty

    when_i_click_the_edit_link_for_max_waiting_list_places
    and_i_set_the_max_waiting_list_places_to_fifteen
    and_i_should_see_the_max_waiting_list_places_setting_is_fifteen

    when_i_click_on_the_audits_link
    then_i_can_see_the_audits_for_my_changes
  end

  def and_a_settings_instance_exists
    create(
      :settings,
      public_access_enabled: true,
      downtime_type: "temporary",
      waiting_list_promotions_per_run: 25,
      max_waiting_list_places: 10,
    )
  end

  def when_i_visit_the_settings_page
    visit admin_settings_path
  end

  def and_i_should_see_the_public_access_enabled_setting_is_enabled
    within("#public-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled Yes")
    end
  end

  def and_i_should_see_the_waiting_list_promotions_per_run_setting_is_twenty_five
    expect(page).to have_content("Promotions per run 25")
  end

  def and_i_should_see_the_max_waiting_list_places_setting_is_ten
    expect(page).to have_content("Maximum places 10")
  end

  def when_i_click_the_edit_link_for_public_access
    within("#public-access") { click_on "Edit Enabled" }
  end

  def and_i_disable_public_access
    choose "No"
    choose "Permanent"
    fill_in "Comment (optional)", with: "Reason for disabling public access"
    click_on "Submit"
  end

  def then_i_see_that_public_access_is_disabled
    within("#public-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled No - permanently offline")
    end
  end

  def when_i_click_the_edit_link_for_waiting_list_promotions_per_run
    click_on "Edit Promotions per run"
  end

  def and_i_set_the_waiting_list_promotions_per_run_to_fifty
    fill_in "Promotions per run", with: 50
    fill_in "Comment (optional)", with: "Reason for updating waiting list promotions per run"
    click_on "Submit"
  end

  def and_i_should_see_the_waiting_list_promotions_per_run_setting_is_fifty
    expect(page).to have_content("Promotions per run 50")
  end

  def when_i_click_the_edit_link_for_max_waiting_list_places
    click_on "Edit Maximum places"
  end

  def and_i_set_the_max_waiting_list_places_to_fifteen
    fill_in "Maximum waiting list places", with: 15
    fill_in "Comment (optional)", with: "Reason for updating maximum waiting list places"
    click_on "Submit"
  end

  def and_i_should_see_the_max_waiting_list_places_setting_is_fifteen
    expect(page).to have_content("Maximum places 15")
  end

  def when_i_click_on_the_audits_link
    click_on "Audits"
  end

  def then_i_can_see_the_audits_for_my_changes
    expect(page)
      .to have_content("Public access enabled set to false, downtime type permanent")
      .and have_content("Reason for disabling public access")
      .and have_content("Updated waiting list promotions per run to 50")
      .and have_content("Reason for updating waiting list promotions per run")
      .and have_content("Updated maximum waiting list places to 15")
      .and have_content("Reason for updating maximum waiting list places")
  end
end
