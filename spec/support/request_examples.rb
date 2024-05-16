module RequestExamples
  shared_examples "requires user to have completed onboarding" do |routes:|
    let(:route_params) { [] }

    routes.each do |path, methods|
      describe "Requires onboarding to have been completed for for #{path} route" do
        methods.each do |method|
          it "requires onboarding to have been completed for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(onboarding_limitations_path)
            follow_redirect!
            expect(response.body)
              .to have_selector(
                ".gem-c-error-alert__message",
                text: "Confirm you understand the limitations of GOV.UK Chat before continuing.",
              )
          end

          context "when session[:onboarding] is 'conversation'" do
            include_context "with onboarding completed"

            it "does not redirect to the onboarding flow for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym, *route_params))

              expect(response.body)
                .not_to have_selector(
                  ".gem-c-error-alert__message",
                  text: "Confirm you understand the limitations of GOV.UK Chat before continuing.",
                )
            end
          end

          context "when covnersation_id is set on the cookie" do
            it "does not redirect to the onboarding flow for #{method} #{path}" do
              conversation = create(:conversation)
              cookies[:conversation_id] = conversation.id

              process(method.to_sym, public_send(path.to_sym, *route_params))

              expect(response.body)
                .not_to have_selector(
                  ".gem-c-error-alert__message",
                  text: "Confirm you understand the limitations of GOV.UK Chat before continuing.",
                )
            end
          end
        end
      end
    end
  end

  shared_examples "redirects user to the conversation when conversation_id is set on cookie" do |routes:|
    routes.each do |path, methods|
      describe "Redirects user to the conversation when conversation_id is set on cookie" do
        methods.each do |method|
          it "redirects user to the conversation when conversation_id is present for #{method} #{path}" do
            conversation = create(:conversation)
            cookies[:conversation_id] = conversation.id

            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(show_conversation_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the conversation page when onboarded and no conversation cookie" do |routes:|
    include_context "with onboarding completed"

    routes.each do |path, methods|
      describe "Redirects user to the new conversation page when session[:onboarding] is 'conversation'" do
        methods.each do |method|
          it "redirects user to the new conversation page when session[:onboarding] is 'conversation' for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(show_conversation_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the privacy page when onboarding limitations has been completed" do |routes:|
    include_context "with onboarding limitations completed"

    routes.each do |path, methods|
      describe "Redirects user to the privacy page when session[:onboarding] is 'privacy'" do
        methods.each do |method|
          it "redirects user to the privacy page when session[:onboarding] is 'privacy' for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(onboarding_privacy_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the onboarding limitations page when onboarding not started" do |routes:|
    routes.each do |path, methods|
      describe "Redirects user to the limitations page when session[:onboarding] isn't 'privacy' or 'conversation'" do
        methods.each do |method|
          it "redirects user to the limitations page when session[:onboarding] isn't 'privacy' or 'conversation' for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(onboarding_limitations_path)
          end
        end
      end
    end
  end

  shared_context "with onboarding completed" do
    before do
      post onboarding_limitations_confirm_path
      post onboarding_privacy_confirm_path
    end
  end

  shared_context "with onboarding limitations completed" do
    before do
      post onboarding_limitations_confirm_path
    end
  end
end
