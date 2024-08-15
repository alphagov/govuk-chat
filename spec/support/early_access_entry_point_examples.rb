module EarlyAccessEntryPointRequestExamples
  shared_examples "redirects user to instant access start page when email is not in the sign_up session" do |routes:|
    routes.each do |path, methods|
      describe "Redirects user to early_access_entry_sign_in_or_up_path when session['sign_up']['email'] is blank" do
        methods.each do |method|
          it "redirects user to the early_access_entry_sign_in_or_up_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(early_access_entry_sign_in_or_up_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to user description path when email is set in the session but user description isn't" do |routes:|
    include_context "with early access user email provided"

    routes.each do |path, methods|
      describe "Redirects user to the user description path when session['sign_up']['user_description'] is blank" do
        methods.each do |method|
          it "redirects user to the user description path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(early_access_entry_user_description_path)
          end
        end
      end
    end
  end

  shared_examples "renders not_accepting_signups page when Settings#sign_up_enabled is false" do |routes:|
    include_context "with early access user email and user description provided"

    routes.each do |path, methods|
      describe "Instant access signups aren't being accepted" do
        methods.each do |method|
          it "renders the not_accepting_signups page for #{method} #{path}" do
            Settings.instance.update!(sign_up_enabled: false)
            process(method.to_sym, public_send(path.to_sym))
            expect(response).to have_http_status(:forbidden)
            expect(response.body)
              .to have_selector(".govuk-heading-xl", text: "GOV.UK Chat is no longer open for new users")
          end
        end
      end
    end
  end

  shared_context "with early access user email provided" do
    before do
      post early_access_entry_sign_in_or_up_path(
        sign_in_or_up_form: { email: "email@test.com" },
      )
    end
  end

  shared_context "with early access user email and user description provided" do
    before do
      post early_access_entry_sign_in_or_up_path(
        sign_in_or_up_form: { email: "email@test.com" },
      )
      post early_access_entry_user_description_path(
        user_description_form: { choice: "business_owner_or_self_employed" },
      )
    end
  end
end
