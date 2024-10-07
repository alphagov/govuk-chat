RSpec.describe WaitingListUser do
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
