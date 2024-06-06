RSpec.describe "Admin::ConversationsController" do
  it_behaves_like "a filterable table of questions in the admin interface", :admin_show_conversation_path, ":show" do
    let(:conversation) { create(:conversation) }
  end

  describe "GET :show" do
    it "renders questions scoped to the conversation" do
      conversation = create(:conversation)
      question_from_conversation = create(:question, conversation:)
      question_from_other_conversation = create(:question)

      get admin_show_conversation_path(conversation)

      expect(response.body).to have_content(question_from_conversation.message)
      expect(response.body).not_to have_content(question_from_other_conversation.message)
    end
  end
end
