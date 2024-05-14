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
        end
      end
    end
  end

  shared_context "with onboarding completed" do
    before do
      post onboarding_privacy_path
    end
  end
end
