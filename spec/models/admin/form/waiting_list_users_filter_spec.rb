RSpec.describe Admin::Form::WaitingListUsersFilter do
  describe "#users" do
    describe "ordering" do
      let!(:created_1_min_ago) { create(:waiting_list_user, email: "alice@example.com", created_at: 1.minute.ago) }
      let!(:created_1_month_ago) { create(:waiting_list_user, email: "betty@example.com", created_at: 1.month.ago) }
      let!(:created_1_hour_ago) { create(:waiting_list_user, email: "clive@example.com", created_at: 1.hour.ago) }

      it "orders the users by the most recently created" do
        users = described_class.new.users
        expect(users).to eq([created_1_min_ago, created_1_hour_ago, created_1_month_ago])
      end

      it "orders the users by the most recently created when the sort param is '-craeted_at'" do
        users = described_class.new(sort: "-created_at").users
        expect(users).to eq([created_1_min_ago, created_1_hour_ago, created_1_month_ago])
      end

      it "orders the users by the least recently created when the sort param is 'created_at'" do
        users = described_class.new(sort: "created_at").users
        expect(users).to eq([created_1_month_ago, created_1_hour_ago, created_1_min_ago])
      end

      it "orders the users by email when the sort param is 'email'" do
        users = described_class.new(sort: "email").users
        expect(users).to eq([created_1_min_ago, created_1_month_ago, created_1_hour_ago])
      end

      it "orders the users by reverse email when the sort param is '-email'" do
        users = described_class.new(sort: "-email").users
        expect(users).to eq([created_1_hour_ago, created_1_month_ago, created_1_min_ago])
      end
    end

    it "paginates the users" do
      create_list(:waiting_list_user, 26)

      users = described_class.new(page: 1).users
      expect(users.count).to eq(25)

      users = described_class.new(page: 2).users
      expect(users.count).to eq(1)
    end
  end

  describe "filtering" do
    it "filters by email" do
      alice = create(:waiting_list_user, email: "alice@example.com")
      bob = create(:waiting_list_user, email: "bob@example.com")
      lisa = create(:waiting_list_user, email: "lisa@example.com")

      filter = described_class.new(email: "alice")
      expect(filter.users).to eq([alice])

      filter = described_class.new(email: "bob")
      expect(filter.users).to eq([bob])

      filter = described_class.new(email: "li")
      expect(filter.users).to contain_exactly(alice, lisa)
    end
  end

  it_behaves_like "a paginatable filter", :waiting_list_user

  it_behaves_like "a sortable filter", "created_at"
end
