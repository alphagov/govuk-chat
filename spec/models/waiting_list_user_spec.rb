RSpec.describe WaitingListUser do
  describe "after_commit" do
    before do
      allow(Metrics).to receive(:increment_counter)
    end

    it "delegates to 'Metrics.increment_counter' with the correct arguments on create" do
      user = create(:waiting_list_user)
      expect(Metrics)
        .to have_received(:increment_counter)
        .with("waiting_list_user_accounts_total", source: user.source)
    end

    it "doesn't call 'Metrics.increment_counter' on update" do
      user = create(:waiting_list_user)
      user.update!(email: "test@test.com")
      expect(Metrics).to have_received(:increment_counter).once
    end
  end

  describe "#destroy_with_audit" do
    it "destroys a user while creating a DeletedWaitingListUser record" do
      instance = create(:waiting_list_user)

      expect { instance.destroy_with_audit(deletion_type: :unsubscribe) }
        .to change(described_class, :count).by(-1)
        .and change(DeletedWaitingListUser, :count).by(1)

      expect(DeletedWaitingListUser.last).to have_attributes(
        id: instance.id,
        user_source: instance.source,
        user_created_at: instance.created_at,
        deletion_type: "unsubscribe",
      )
    end
  end
end
