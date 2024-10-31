RSpec.describe Admin::Filters::WaitingListUsersFilter do
  describe "#results" do
    describe "ordering" do
      let!(:created_1_min_ago) { create(:waiting_list_user, email: "alice@example.com", created_at: 1.minute.ago) }
      let!(:created_1_month_ago) { create(:waiting_list_user, email: "betty@example.com", created_at: 1.month.ago) }
      let!(:created_1_hour_ago) { create(:waiting_list_user, email: "clive@example.com", created_at: 1.hour.ago) }

      it "orders the results by the most recently created" do
        results = described_class.new.results
        expect(results).to eq([created_1_min_ago, created_1_hour_ago, created_1_month_ago])
      end

      it "orders the results by the most recently created when the sort param is '-created_at'" do
        results = described_class.new(sort: "-created_at").results
        expect(results).to eq([created_1_min_ago, created_1_hour_ago, created_1_month_ago])
      end

      it "orders the results by the least recently created when the sort param is 'created_at'" do
        results = described_class.new(sort: "created_at").results
        expect(results).to eq([created_1_month_ago, created_1_hour_ago, created_1_min_ago])
      end

      it "orders the results by email when the sort param is 'email'" do
        results = described_class.new(sort: "email").results
        expect(results).to eq([created_1_min_ago, created_1_month_ago, created_1_hour_ago])
      end

      it "orders the results by reverse email when the sort param is '-email'" do
        results = described_class.new(sort: "-email").results
        expect(results).to eq([created_1_hour_ago, created_1_month_ago, created_1_min_ago])
      end
    end

    it "paginates the results" do
      create_list(:waiting_list_user, 26)

      results = described_class.new(page: 1).results
      expect(results.count).to eq(25)

      results = described_class.new(page: 2).results
      expect(results.count).to eq(1)
    end
  end

  describe "filtering" do
    it "filters by email" do
      alice = create(:waiting_list_user, email: "alice@example.com")
      bob = create(:waiting_list_user, email: "bob@example.com")
      lisa = create(:waiting_list_user, email: "lisa@example.com")

      filter = described_class.new(email: "alice")
      expect(filter.results).to eq([alice])

      filter = described_class.new(email: "bob")
      expect(filter.results).to eq([bob])

      filter = described_class.new(email: "li")
      expect(filter.results).to contain_exactly(alice, lisa)
    end

    it "filters by previous sign up denied status" do
      user_previously_denied_sign_up = create(:waiting_list_user, previous_sign_up_denied: true)
      user_not_previously_denied_sign_up = create(:waiting_list_user, previous_sign_up_denied: false)

      filter = described_class.new(previous_sign_up_denied: "true")
      expect(filter.results).to eq([user_previously_denied_sign_up])

      filter = described_class.new(previous_sign_up_denied: "false")
      expect(filter.results).to eq([user_not_previously_denied_sign_up])
    end
  end

  it_behaves_like "a paginatable filter", :waiting_list_user

  it_behaves_like "a sortable filter", "created_at"
end
