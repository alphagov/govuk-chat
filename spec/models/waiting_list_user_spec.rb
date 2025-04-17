RSpec.describe WaitingListUser do
  include_examples "user research question enums match config"

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

    it "records the user id of the admin that deleted the user if passed one" do
      instance = create(:waiting_list_user)
      admin_user_id = SecureRandom.uuid

      expect { instance.destroy_with_audit(deletion_type: :admin, deleted_by_signon_user_id: admin_user_id) }
        .to change(described_class, :count).by(-1)
        .and change(DeletedWaitingListUser, :count).by(1)

      expect(DeletedWaitingListUser.last).to have_attributes(
        id: instance.id,
        user_source: instance.source,
        user_created_at: instance.created_at,
        deletion_type: "admin",
        deleted_by_signon_user_id: admin_user_id,
      )
    end
  end

  describe ".aggregate_export_data" do
    it "returns a hash of aggregated waiting list user statistics created before the time passed in" do
      freeze_time do
        create(:waiting_list_user, source: :admin_added, created_at: 2.minutes.ago)
        create_list(:waiting_list_user, 2, source: :insufficient_instant_places, created_at: 2.minutes.ago)
        create(:deleted_waiting_list_user, deletion_type: :unsubscribe, created_at: 2.minutes.ago)
        create_list(:deleted_waiting_list_user, 2, deletion_type: :admin, created_at: 2.minutes.ago)
        create(:deleted_waiting_list_user, deletion_type: :promotion, created_at: 2.minutes.ago)
        create(:waiting_list_user, source: :admin_added)
        create(:deleted_waiting_list_user, deletion_type: :promotion)

        until_date = 1.minute.ago
        expect(described_class.aggregate_export_data(until_date)).to eq(
          "exported_until" => until_date.as_json,
          "current_user_sources" => {
            "admin_added" => 1,
            "insufficient_instant_places" => 2,
          },
          "deletion_types" => {
            "unsubscribe" => 1,
            "admin" => 2,
            "promotion" => 1,
          },
          "current" => 3,
          "deleted" => 4,
          "all_time" => 7,
        )
      end
    end
  end
end
