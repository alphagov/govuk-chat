RSpec.describe "users rake tasks" do
  describe "users:promote_waiting_list" do
    let(:task_name) { "users:promote_waiting_list" }
    let!(:waiting_list_users) { create_list :waiting_list_user, 3 }
    let(:early_access_users) { EarlyAccessUser.all }

    before do
      Rake::Task[task_name].reenable
    end

    it "add EarlyAccessUsers and deletes WaitingListUsers" do
      expect { Rake::Task[task_name].invoke }.to change(EarlyAccessUser, :count).by(3)
      .and change(WaitingListUser, :count).by(-3)
    end

    it "copies the attributes across correctly" do
      Rake::Task[task_name].invoke
      expected = waiting_list_users.map { |u| [u.email, u.user_description, u.reason_for_visit] }
      actual = early_access_users.pluck(:email, :user_description, :reason_for_visit)
      expect(actual).to eq(expected)
    end
  end
end
