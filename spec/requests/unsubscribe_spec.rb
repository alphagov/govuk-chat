RSpec.describe "UnsubscribeController" do
  shared_examples "returns 404 for invalid user id or token" do |path|
    it "returns a 404 if user id is invalid" do
      get public_send(path, SecureRandom.uuid, user.unsubscribe_token)

      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 if the token is invalid" do
      get waiting_list_user_unsubscribe_path(user.id, "invalid-token")
      get public_send(path.to_sym, user.id, SecureRandom.uuid)

      expect(response).to have_http_status(:not_found)
    end
  end

  it_behaves_like "throttles traffic from a single IP address",
                  routes: { waiting_list_user_unsubscribe_path: %i[get] }, limit: 20, period: 5.minutes do
                    let(:route_params) { { id: SecureRandom.uuid, token: SecureRandom.uuid } }
                  end

  it_behaves_like "throttles traffic from a single IP address",
                  routes: { early_access_user_unsubscribe_path: %i[get] }, limit: 20, period: 5.minutes do
                    let(:route_params) { { id: SecureRandom.uuid, token: SecureRandom.uuid } }
                  end

  describe "HEAD :waiting_list_user" do
    it "returns a success without unsubscribing the user" do
      user = create(:waiting_list_user)

      expect { head waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token) }
        .not_to change(WaitingListUser, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET :waiting_list_user" do
    include_examples "returns 404 for invalid user id or token", :waiting_list_user_unsubscribe_path do
      let(:user) { create(:waiting_list_user) }
    end

    context "when the token is valid" do
      let(:user) { create(:waiting_list_user) }

      it "deletes the user" do
        get waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token)

        expect(WaitingListUser.exists?(user.id)).to be(false)
      end

      it "creates a DeletedEarlyAccessUser the user" do
        expect { get waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token) }
          .to change { DeletedWaitingListUser.where(deletion_type: :unsubscribe).count }.by(1)
      end

      it "renders a confirmation view" do
        get waiting_list_user_unsubscribe_path(user.id, user.unsubscribe_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_content("You’ve been removed from the waitlist")
      end
    end
  end

  describe "HEAD :early_access_user" do
    it "returns a success without unsubscribing the user" do
      user = create(:early_access_user)

      expect { head early_access_user_unsubscribe_path(user.id, user.unsubscribe_token) }
        .not_to change(EarlyAccessUser, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET :early_access_user" do
    include_examples "returns 404 for invalid user id or token", :early_access_user_unsubscribe_path do
      let(:user) { create(:early_access_user) }
    end

    context "when the token is valid" do
      let(:user) { create(:early_access_user) }

      it "deletes the user" do
        get early_access_user_unsubscribe_path(user.id, user.unsubscribe_token)

        expect(EarlyAccessUser.exists?(user.id)).to be(false)
      end

      it "creates a DeletedEarlyAccessUser the user" do
        expect { get early_access_user_unsubscribe_path(user.id, user.unsubscribe_token) }
          .to change { DeletedEarlyAccessUser.where(deletion_type: :unsubscribe).count }.by(1)
      end

      it "renders a confirmation view" do
        get early_access_user_unsubscribe_path(user.id, user.unsubscribe_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_content("Thanks for helping to test GOV.UK Chat")
      end
    end
  end
end
