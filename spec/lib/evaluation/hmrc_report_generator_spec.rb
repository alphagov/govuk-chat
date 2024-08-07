RSpec.describe Evaluation::HmrcReportGenerator do
  let(:evaluation_questions) { ["How do I pay VAT?", "Do I need a visa?"] }

  let(:answers) do
    [
      build(
        :answer,
        message: "First answer from OpenAI",
        sources: [
          build(:answer_source, exact_path: "/vat-payments/late-payments"),
          build(:answer_source, exact_path: "/vat-payments/pay-online"),
          build(:answer_source, exact_path: "/vat-payments/not-used", used: false),
        ],
      ),
      build(
        :answer,
        message: "Second answer from OpenAI",
        sources: [
          build(:answer_source, exact_path: "/visas/check-if-you-need-a-visa"),
        ],
      ),
    ]
  end

  before do
    allow(described_class).to receive(:evaluation_questions).and_return(evaluation_questions)
    allow(AnswerComposition::Composer).to receive(:call).and_return(*answers)
  end

  describe ".evaluation_questions" do
    it "loads the questions from the YAML file" do
      questions = described_class.evaluation_questions
      expect(questions).to be_an(Array)
      expect(questions.map(&:class).uniq).to eq([String])
    end
  end

  describe ".call" do
    it "returns the items" do
      items = described_class.call

      header = items[0]
      rows = items[1..]

      expect(header).to eq(["Question", "Answer", "Sources Returned"])

      expect(rows).to eq([
        [
          "How do I pay VAT?",
          "First answer from OpenAI",
          "https://www.gov.uk/vat-payments/late-payments\nhttps://www.gov.uk/vat-payments/pay-online",
        ],
        [
          "Do I need a visa?",
          "Second answer from OpenAI",
          "https://www.gov.uk/visas/check-if-you-need-a-visa",
        ],
      ])
    end
  end
end
