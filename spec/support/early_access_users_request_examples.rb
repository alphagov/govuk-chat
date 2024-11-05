module EarlyAccessUsersRequestExamples
  shared_examples "redirects to the admin_early_access_user_path if the user is revoked" do |routes:|
    routes.each do |path, methods|
      describe "Redirects to admin_early_access_user_path if the user is revoked" do
        let(:user) { create(:early_access_user, :revoked) }

        methods.each do |method|
          it "redirects user to the admin_early_access_user_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, user))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(admin_early_access_user_path(user))
          end
        end
      end
    end
  end

  shared_examples "redirects to the admin_early_access_user_path if the user is shadow banned" do |routes:|
    routes.each do |path, methods|
      describe "Redirects to admin_early_access_user_path if the user is shadow banned" do
        let(:user) { create(:early_access_user, :shadow_banned) }

        methods.each do |method|
          it "redirects user to the admin_early_access_user_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, user))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(admin_early_access_user_path(user))
          end
        end
      end
    end
  end

  shared_examples "redirects to the admin_early_access_user_path if the user has full access" do |routes:|
    routes.each do |path, methods|
      describe "Redirects to admin_early_access_user_path if the user has full access" do
        let(:user) { create(:early_access_user) }

        methods.each do |method|
          it "redirects user to the admin_early_access_user_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, user))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(admin_early_access_user_path(user))
          end
        end
      end
    end
  end
end
