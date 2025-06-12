module AdminSettingsExamples
  shared_examples "limits access to users with the admin-area-settings permission" do |routes:|
    routes.each do |route, methods|
      describe "responds with forbidden if user doesn't have admin-area-settings permission for #{route}" do
        methods.each do |method|
          it "returns forbidden for #{method} #{route} without the permission" do
            login_as(create(:signon_user))
            process(method.to_sym, public_send(route.to_sym))
            expect(response).to have_http_status(:forbidden)
          end

          it "doesn't return foribidden for #{method} #{route} with the permission" do
            user = create(:signon_user, :admin_area_settings)
            login_as(user)

            process(method.to_sym, public_send(route.to_sym))

            expect(response).not_to have_http_status(:forbidden)
          end
        end
      end
    end
  end
end
