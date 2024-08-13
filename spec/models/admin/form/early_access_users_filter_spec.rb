RSpec.describe Admin::Form::EarlyAccessUsersFilter do
  describe "#users" do
    describe "ordering" do
      let!(:logged_in_1_min_ago) { create(:early_access_user, email: "alice@example.com", last_login_at: 1.minute.ago) }
      let!(:never_logged_in) { create(:early_access_user, email: "betty@example.com", last_login_at: nil) }
      let!(:logged_in_1_hour_ago) { create(:early_access_user, email: "clive@example.com", last_login_at: 1.hour.ago) }

      it "orders the users by the most recently logged in" do
        users = described_class.new.users
        expect(users).to eq([logged_in_1_min_ago, logged_in_1_hour_ago, never_logged_in])
      end

      it "orders the users by the most recently logged in when the sort param is '-last_login_at'" do
        users = described_class.new(sort: "-last_login_at").users
        expect(users).to eq([logged_in_1_min_ago, logged_in_1_hour_ago, never_logged_in])
      end

      it "orders the users by the least recently logged in when the sort param is 'last_login_at'" do
        users = described_class.new(sort: "last_login_at").users
        expect(users).to eq([never_logged_in, logged_in_1_hour_ago, logged_in_1_min_ago])
      end

      it "orders the users by email when the sort param is 'email'" do
        users = described_class.new(sort: "email").users
        expect(users).to eq([logged_in_1_min_ago, never_logged_in, logged_in_1_hour_ago])
      end

      it "orders the users by reverse email when the sort param is '-email'" do
        users = described_class.new(sort: "-email").users
        expect(users).to eq([logged_in_1_hour_ago, never_logged_in, logged_in_1_min_ago])
      end
    end

    it "paginates the users" do
      create_list(:early_access_user, 26)

      users = described_class.new(page: 1).users
      expect(users.count).to eq(25)

      users = described_class.new(page: 2).users
      expect(users.count).to eq(1)
    end
  end

  it_behaves_like "a paginatable filter", :early_access_user

  it_behaves_like "a sortable filter", "last_login_at"
end
