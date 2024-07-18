RSpec.describe AnswerComposition::Pipeline::ForbiddenWordsChecker do
  let(:context) { build(:answer_pipeline_context) }

  before do
    allow(Rails.configuration).to receive(:question_forbidden_words).and_return(%w[forbidden])
  end

  it "returns nil when the contexts question_message does not contain a forbidden word" do
    expect { described_class.call(context) }.not_to change(context, :aborted?).from(false)
  end

  context "when the contexts question_message contains a forbidden word" do
    let(:question) { build(:question, message: "This is forbidden") }
    let(:context) { build(:answer_pipeline_context, question:) }

    it "aborts the pipeline and updates the answers status and message attributes" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
        .and change { context.answer.status }.to("abort_forbidden_words")
        .and change { context.answer.message }.to(Answer::CannedResponses::FORBIDDEN_WORDS_RESPONSE)
    end
  end
end
