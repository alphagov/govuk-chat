RSpec.describe AnswerComposition::ForbiddenTermsChecker do
  let(:answer) { build(:answer, message: answer_message) }
  let(:answer_message) { "clean answer message" }

  before do
    allow(Rails.configuration).to receive(:forbidden_terms).and_return(Set.new(["badterm", "extra bad term"]))
  end

  it "assigns the forbidden_terms_checker metric to the answer" do
    allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
    described_class.call(answer)
    expect(answer.metrics["forbidden_terms_checker"]).to eq({ "duration" => 1.5 })
  end

  shared_examples "doesn't update answers message or status" do
    it "does not change the message or status" do
      expect { described_class.call(answer) }
        .to not_change(answer, :message)
        .and not_change(answer, :status)
    end
  end

  shared_examples "updates the answers message and status" do
    it "updates the message to the forbidden terms message" do
      expect { described_class.call(answer) }
        .to change(answer, :message).to(Answer::CannedResponses::FORBIDDEN_TERMS_MESSAGE)
    end

    it "updates the status to abort forbidden terms" do
      expect { described_class.call(answer) }
        .to change(answer, :status).to("abort_forbidden_terms")
    end
  end

  context "when there are no forbidden terms in the answer message" do
    it_behaves_like "doesn't update answers message or status"
  end

  context "when a fordbidden term is a substring" do
    it_behaves_like "doesn't update answers message or status" do
      let(:answer_message) { "clean answer messagebadterm" }
    end
  end

  context "when there is a forbidden term in the answer message" do
    it_behaves_like "updates the answers message and status" do
      let(:answer_message) { "answer message with badterm" }
    end

    context "and the forbidden phrase is multiple words" do
      it_behaves_like "updates the answers message and status" do
        let(:answer_message) { "answer message with extra bad term in it" }
      end
    end

    context "and the forbidden term is preceded or followed by punctuation" do
      it_behaves_like "updates the answers message and status" do
        let(:answer_message) { "answer message with badterm!" }
      end

      it_behaves_like "updates the answers message and status" do
        let(:answer_message) { "answer message with !badterm" }
      end
    end

    context "and the forbidden term is preceded or followed by a number" do
      it_behaves_like "updates the answers message and status" do
        let(:answer_message) { "answer message with badterm1" }
      end

      it_behaves_like "updates the answers message and status" do
        let(:answer_message) { "answer message with 1badterm" }
      end
    end
  end
end
