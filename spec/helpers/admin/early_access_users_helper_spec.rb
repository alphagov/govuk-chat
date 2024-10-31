RSpec.describe Admin::EarlyAccessUsersHelper do
  let(:user) { create(:early_access_user) }

  describe "#early_access_user_index_email_field" do
    it "returns the email with a link to the user's page" do
      user = create(:early_access_user)
      expect(helper.early_access_user_index_email_field(user))
        .to have_link(user.email, href: admin_early_access_user_path(user))
        .and have_content(user.email)
    end

    it "strikes through the link and appends a (revoked) suffix if the user's access is revoked" do
      user = create(:early_access_user, :revoked)
      expect(helper.early_access_user_index_email_field(user))
        .to have_link(user.email, href: admin_early_access_user_path(user))
        .and have_selector("s", text: user.email)
        .and have_content("#{user.email} (revoked)")
    end

    it "strikes through the link and appends a (shadow banned) suffix if the user is shadow banned" do
      user = create(:early_access_user, :shadow_banned)
      expect(helper.early_access_user_index_email_field(user))
        .to have_link(user.email, href: admin_early_access_user_path(user))
        .and have_selector("s", text: user.email)
        .and have_content("#{user.email} (shadow banned)")
    end
  end

  describe "#question_show_summary_list_rows" do
    it "returns 0 if the user hasn't asked a question" do
      user = create(:early_access_user, questions_count: 0)
      expect(helper.early_access_user_index_questions_field(user)).to eq("0")
    end

    context "when the user has an unlimited question" do
      it "returns the count of the user questions as a link to the user's questions" do
        user = create(:early_access_user, individual_question_limit: nil, questions_count: 5)
        expect(helper.early_access_user_index_questions_field(user))
          .to have_link("5", href: admin_questions_path(user_id: user.id))
      end
    end

    context "when the user has a limited question allowance" do
      it "returns the count of the user questions as a link to the user's questions and their question limit" do
        user = create(:early_access_user, individual_question_limit: 5, questions_count: 2)
        expect(helper.early_access_user_index_questions_field(user))
          .to have_link("2", href: admin_questions_path(user_id: user.id))
          .and have_content("2 / 5")
      end
    end
  end
end
