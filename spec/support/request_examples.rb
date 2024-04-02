module RequestExamples
  shared_examples "requires user to have accepted chat risks" do |routes:|
    let(:route_params) { [] }

    routes.each do |path, methods|
      describe "Requiring chat risks to be accepted for #{path} route" do
        methods.each do |method|
          it "requires chat risks to be accepted for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(chat_onboarding_path)
            follow_redirect!
            expect(response.body)
              .to have_selector(
                ".gem-c-error-alert__message",
                text: "Check the checkbox to show you understand the guidance",
              )
          end
        end
      end
    end
  end

  shared_context "with chat risks accepted" do
    before do
      post onboarding_confirm_path, params: { confirm_understand_risk: { confirmation: "understand_risk" } }
    end
  end
end
