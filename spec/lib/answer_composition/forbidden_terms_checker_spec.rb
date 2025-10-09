RSpec.describe AnswerComposition::ForbiddenTermsChecker do
  let(:answer) do
    build(
      :answer,
      message: answer_message,
      sources: [
        build(:answer_source, used: false),
        build(:answer_source, used: true),
      ],
    )
  end
  let(:answer_message) { "clean answer message" }

  before do
    allow(Rails.configuration.govuk_chat_private).to receive(:forbidden_terms).and_return(Set.new(["badterm", "extra bad term"]))
  end

  it "assigns the forbidden_terms_checker metric to the metrics values on the answer" do
    answer.assign_metrics("existing_metric", { duration: 1 })
    allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
    described_class.call(answer)
    expect(answer.metrics).to match(hash_including(
                                      "existing_metric" => { duration: 1 },
                                      "forbidden_terms_checker" => { duration: 1.5 },
                                    ))
  end

  shared_examples "doesn't update answers message or status" do
    it "does not change the message or status" do
      expect { described_class.call(answer) }
        .to not_change(answer, :message)
        .and not_change(answer, :status)
    end
  end

  shared_examples "updates the answers message and status" do |forbidden_words = %w[badterm]|
    it "updates the message to the forbidden terms message" do
      expect { described_class.call(answer) }
        .to change(answer, :message).to(Answer::CannedResponses::FORBIDDEN_TERMS_MESSAGE)
    end

    it "updates the status and forbidden_terms_detected" do
      expect { described_class.call(answer) }
        .to change(answer, :status).to("guardrails_forbidden_terms")
        .and change(answer, :forbidden_terms_detected).to eq(forbidden_words)
    end

    it "sets the sources as unused" do
      described_class.call(answer)
      expect(answer.sources.all?(&:used?)).to be(false)
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
      it_behaves_like "updates the answers message and status", ["extra bad term"] do
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

    context "and there are multiple forbidden terms" do
      it_behaves_like "updates the answers message and status", ["badterm", "extra bad term"] do
        let(:answer_message) { "answer message with badterm and extra bad term" }
      end
    end

    context "and there are multiple consecutive forbidden terms" do
      it_behaves_like "updates the answers message and status", ["badterm", "extra bad term"] do
        let(:answer_message) { "answer message with badterm extra bad term" }
      end
    end
  end
end
