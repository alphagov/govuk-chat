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
end
