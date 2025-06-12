RSpec.describe "Admin user updates settings" do
  scenario do
    given_i_am_an_admin
    and_a_settings_instance_exists

    when_i_visit_the_settings_page
    and_i_should_see_the_web_access_enabled_setting_is_enabled
    and_i_should_see_the_api_access_enabled_setting_is_enabled

    when_i_click_the_edit_link_for_web_access
    and_i_disable_web_access
    then_i_see_that_web_access_is_disabled

    when_i_click_the_edit_link_for_api_access
    and_i_disable_api_access
    then_i_see_that_api_access_is_disabled

    when_i_click_on_the_audits_link
    then_i_can_see_the_audits_for_my_changes
  end

  def and_a_settings_instance_exists
    create(:settings, web_access_enabled: true)
  end

  def when_i_visit_the_settings_page
    visit admin_settings_path
  end

  def and_i_should_see_the_web_access_enabled_setting_is_enabled
    within("#web-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled Yes")
    end
  end

  def and_i_should_see_the_api_access_enabled_setting_is_enabled
    within("#api-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled Yes")
    end
  end

  def when_i_click_the_edit_link_for_web_access
    within("#web-access") { click_on "Edit Enabled" }
  end

  def when_i_click_the_edit_link_for_api_access
    within("#api-access") { click_on "Edit Enabled" }
  end

  def and_i_disable_web_access
    choose "No"
    fill_in "Comment (optional)", with: "Reason for disabling web access"
    click_on "Submit"
  end

  def and_i_disable_api_access
    choose "No"
    fill_in "Comment (optional)", with: "Reason for disabling API access"
    click_on "Submit"
  end

  def then_i_see_that_web_access_is_disabled
    within("#web-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled No")
    end
  end

  def then_i_see_that_api_access_is_disabled
    within("#api-access") do
      expect(page).to have_selector(".govuk-summary-list__row", text: "Enabled No")
    end
  end

  def when_i_click_on_the_audits_link
    click_on "Audits"
  end

  def then_i_can_see_the_audits_for_my_changes
    expect(page)
      .to have_content("Web access enabled set to false")
      .and have_content("Reason for disabling web access")
      .and have_content("API access enabled set to false")
  end
end
