RSpec.describe "Settings endpoints" do
  describe "Admin::SettingsController" do
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

      it "renders 'No audits.' when there are no audits" do
        get admin_settings_audits_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_content("No audits.")
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

  describe "Admin::Settings::InstantAccessPlacesController" do
    describe "GET :edit" do
      it "renders the edit page successfully" do
        get admin_edit_instant_access_places_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".govuk-heading-xl", text: "Edit instant access places")
      end
    end

    describe "PATCH :update" do
      it "updates the instant access places and redirects to the settings page with valid params" do
        settings = create(:settings, instant_access_places: 10)

        expect {
          patch admin_update_instant_access_places_path,
                params: { instant_access_places_form: { places: 5 } }
        }
          .to change(SettingsAudit, :count).by(1)
        expect(response).to redirect_to(admin_settings_path)
        expect(flash[:notice]).to eq("Instant access places updated")
        expect(settings.reload.instant_access_places).to eq(15)
      end

      it "re-renders the edit page when given invalid params" do
        patch admin_update_instant_access_places_path,
              params: { instant_access_places_form: { places: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end

  describe "Admin::Settings::DelayedAccessPlacesController" do
    describe "GET :edit" do
      it "renders the edit page successfully" do
        get admin_edit_delayed_access_places_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".govuk-heading-xl", text: "Edit delayed access places")
      end
    end

    describe "PATCH :update" do
      it "updates the delayed access places and redirects to the settings page with valid params" do
        settings = create(:settings, delayed_access_places: 10)

        expect {
          patch admin_update_delayed_access_places_path,
                params: { delayed_access_places_form: { places: 5 } }
        }
          .to change(SettingsAudit, :count).by(1)
        expect(response).to redirect_to(admin_settings_path)
        expect(flash[:notice]).to eq("Delayed access places updated")
        expect(settings.reload.delayed_access_places).to eq(15)
      end

      it "re-renders the edit page when given invalid params" do
        patch admin_update_delayed_access_places_path,
              params: { delayed_access_places_form: { places: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end

  describe "Admin::Settings::SignUpEnabledController" do
    describe "GET :edit" do
      it "renders the edit page successfully" do
        get admin_edit_sign_up_enabled_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".govuk-heading-xl", text: "Edit sign up enabled")
      end
    end

    describe "PATCH :update" do
      it "updates the instant access places and redirects to the settings page with valid params" do
        settings = create(:settings, sign_up_enabled: false)

        expect {
          patch admin_update_sign_up_enabled_path,
                params: { sign_up_enabled_form: { enabled: "true" } }
        }
          .to change(SettingsAudit, :count).by(1)
        expect(response).to redirect_to(admin_settings_path)
        expect(flash[:notice]).to eq("Sign up enabled updated")
        expect(settings.reload.sign_up_enabled).to be(true)
      end

      it "re-renders the edit page when given invalid params" do
        patch admin_update_sign_up_enabled_path,
              params: { sign_up_enabled_form: { enabled: "true", author_comment: "s" * 256 } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end
end
