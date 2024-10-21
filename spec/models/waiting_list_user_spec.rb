RSpec.describe WaitingListUser do
  describe ".users_to_promote" do
    it "returns an array of waiting_list_users" do
      create_list(:waiting_list_user, 3)
      result = described_class.users_to_promote(2)

      expect(result.count).to eq(2)
      expect(result).to all(be_a(described_class))
    end

    it "randomises the order of the returned waiting_list_users" do
      expect(described_class.users_to_promote(1).to_sql).to include("RANDOM()")
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
