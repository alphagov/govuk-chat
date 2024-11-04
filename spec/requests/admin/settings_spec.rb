RSpec.describe "Admin::SettingsController" do
  describe "GET :show" do
    it "creates the settings singleton and renders the page successfully on first visit" do
      expect { get admin_settings_path }.to change(Settings, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".govuk-heading-xl", text: "Settings")
    end

    it "renders the page successfully on subsequent visits" do
      create(:settings)
      expect { get admin_settings_path }.to not_change(Settings, :count)
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".govuk-heading-xl", text: "Settings")
    end
  end

  describe "GET :audits" do
    it "renders a list of audits :desc successfully" do
      create(:settings_audit, created_at: 2.days.ago, action: "Appears second")
      create(:settings_audit, created_at: 1.day.ago, action: "Appears first")

      get admin_settings_audits_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content(/Appears first.*Appears second/m)
    end

    it "renders 'No audited settings changes.' when there are no audits" do
      get admin_settings_audits_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("No audited settings changes.")
    end

    context "when there are more than 25 audits" do
      it "paginates the audits correctly on page 1" do
        create_list(:settings_audit, 26)

        get admin_settings_audits_path

        expect(response.body)
          .to have_link("Next page", href: admin_settings_audits_path(page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
          .and have_no_content("Previous page")
      end

      it "paginates the audits correctly on page 2" do
        create_list(:settings_audit, 26)

        get admin_settings_audits_path(page: 2)

        expect(response.body)
        .to have_link("Previous page", href: admin_settings_audits_path(page: 1))
        .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        .and have_no_content("Next page")
      end
    end
  end
end
