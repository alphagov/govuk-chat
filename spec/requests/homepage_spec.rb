RSpec.describe "HomepageController" do
  it_behaves_like "redirects to homepage if authentication is not enabled",
                  routes: { homepage_path: %i[post] }

  it_behaves_like "throttles traffic from a single IP address",
                  routes: { homepage_path: %i[post] }, limit: 10, period: 5.minutes

  describe "GET :index" do
    context "when early access authentication is enabled" do
      before do
        allow(Rails.configuration).to receive(:available_without_early_access_authentication).and_return(false)
      end

      it "renders the early access authentication welcome page" do
        get homepage_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".app-c-chat-introduction-title__title", text: "Try GOV.UK Chat")
      end
    end

    context "when early access authentication is disabled" do
      before do
        allow(Rails.configuration).to receive(:available_without_early_access_authentication).and_return(true)
      end

      it "renders the welcome page" do
        get homepage_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".app-c-chat-introduction-title__title", text: "GOV.UK Chat")
      end
    end

    context "when the user is signed in" do
      include_context "when signed in"

      it "renders the welcome page" do
        get homepage_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_text("You are currently signed in with #{EarlyAccessUser.last.email}")
      end

      it "does not cache the page" do
        get homepage_path

        expect(response.headers["Cache-Control"]).to eq("max-age=0, private, must-revalidate")
      end
    end

    it "sets the cache headers" do
      get homepage_path

      expect(response.headers["Cache-Control"]).to eq("max-age=60, public")
      expect(response.headers["Vary"]).to eq("Cookie")
    end
  end

  describe "POST :sign_in_or_up" do
    let(:early_access_user) { create :early_access_user }

    context "when valid params are passed" do
      context "and the user doesn't have an account" do
        it "sets the users email_address in the session" do
          post homepage_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          expect(session["sign_up"]).to eq({
            "email" => "email@test.com", "previous_sign_up_denied" => false
          })
        end

        context "and the user has previous been denied sign up" do
          include_context "with early access user email, user description of none, and reason for sign up provided"

          it "sets previous_sign_up_denied to true in the session" do
            post homepage_path(sign_in_or_up_form: { email: "email@test.com" })

            expect(session["sign_up"]["previous_sign_up_denied"]).to be(true)
          end
        end

        it "redirects to the user_description path" do
          post homepage_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          expect(response).to redirect_to(sign_up_user_description_path)
        end
      end

      context "and the user already has an account" do
        it "responds with a successful status" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the email_sent template" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You've been sent a new link")
        end

        it "emails a magic link to the user" do
          expect {
            post homepage_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        end
      end

      context "and the user is on the waiting list" do
        let!(:waiting_list_user) { create :waiting_list_user }

        it "responds with a successful status" do
          post homepage_path(
            sign_in_or_up_form: { email: waiting_list_user.email },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the already_on_waitlist template" do
          post homepage_path(
            sign_in_or_up_form: { email: waiting_list_user.email },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You're already on the waitlist")
        end
      end

      context "and the user has a revoked account" do
        before do
          early_access_user.touch(:revoked_at)
        end

        it "responds with a forbidden status" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the access revoked template" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body)
            .to have_selector(".govuk-heading-xl", text: "You do not have access to this page")
            .and have_link("report a technical fault", href: "https://surveys.publishing.service.gov.uk/s/govuk-chat-support")
        end

        it "doesn't send a magic link to the user" do
          expect {
            post homepage_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.not_to change(EarlyAccessAuthMailer.deliveries, :count)
        end
      end

      context "and the user has requested 3 links in the last 5 minutes" do
        before do
          create_list(:passwordless_session, 3, authenticatable: early_access_user)
        end

        it "responds with a too_many_requests status" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:too_many_requests)
        end

        it "renders the magic_link_limit template" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body)
            .to have_selector(".govuk-heading-xl", text: "You've requested too many links")
        end

        it "doesn't send a magic link to the user" do
          expect {
            post homepage_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.not_to change(EarlyAccessAuthMailer.deliveries, :count)
        end
      end
    end

    context "when invalid params are passed" do
      it "renders the sign_in_or_up page with errors" do
        post homepage_path(sign_in_or_up_form: { email: "" })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end
end
