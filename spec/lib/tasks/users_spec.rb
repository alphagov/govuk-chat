RSpec.describe "users rake tasks" do
  describe "users:promote_waiting_list" do
    let(:task_name) { "users:promote_waiting_list" }
    let!(:waiting_list_users) { create_list :waiting_list_user, 3 }
    let(:early_access_users) { EarlyAccessUser.all }

    before do
      Rake::Task[task_name].reenable
    end

    shared_examples "makes the correct changes" do |expected_promotions|
      it "add EarlyAccessUsers and deletes WaitingListUsers" do
        expect { Rake::Task[task_name].invoke }.to change(EarlyAccessUser, :count).by(expected_promotions)
          .and change(WaitingListUser, :count).by(-expected_promotions)
      end

      it "copies the attributes across correctly" do
        Rake::Task[task_name].invoke
        expected = waiting_list_users.map { |u| [u.email, u.user_description, u.reason_for_visit] }
        actual = early_access_users.pluck(:email, :user_description, :reason_for_visit)
        expect(actual).to eq(expected)
      end

      it "locks the settings and decrements the available places" do
        settings = create :settings
        allow(Settings).to receive(:instance).and_return(settings)
        expect(settings).to receive(:with_lock).and_call_original
        expect { Rake::Task[task_name].invoke }.to change(settings, :delayed_access_places).by(-expected_promotions)
      end
    end

    context "when number of waiting list users is with limits" do
      before do
        Settings.instance.update!(delayed_access_places: 50)
      end

      it_behaves_like "makes the correct changes", 3
    end
  end
end
