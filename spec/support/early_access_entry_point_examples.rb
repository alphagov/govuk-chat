module EarlyAccessEntryPointRequestExamples
  shared_examples "redirects user to instant access start page when email is not in the sign_up session" do |routes:|
    routes.each do |path, methods|
      describe "Redirects user to early_access_entry_path when session['sign_up']['email'] is blank" do
        methods.each do |method|
          it "redirects user to the early_access_entry_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(early_access_entry_path)
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

  shared_context "with early access user email provided" do
    before do
      post early_access_entry_path(
        early_access_entry_form: { email: "email@test.com" },
      )
    end
  end

  shared_context "with early access user email and user description provided" do
    before do
      post early_access_entry_path(
        early_access_entry_form: { email: "email@test.com" },
      )
      post early_access_entry_user_description_path(
        user_description_form: { choice: "business_owner_or_self_employed" },
      )
    end
  end
end
