module GuardrailsExamples
  shared_examples "a passing guardrail pipeline step" do |guardrail_name|
    it "calls the guardrails with the answer message" do
      described_class.call(context)
      expect(Guardrails::MultipleChecker)
        .to have_received(:call)
        .with(context.answer.message, guardrail_name)
    end

    it "does not change the message" do
      expect { described_class.call(context) }.not_to change(context.answer, :message)
    end

    it "sets the status" do
      expect { described_class.call(context) }
        .to change(context.answer, "#{guardrail_name}_status").to("pass")
    end

    it "assigns the llm response to the answer" do
      described_class.call(context)

      expect(context.answer.llm_responses[guardrail_name])
        .to eq(guardrail_response.llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics[guardrail_name]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
        llm_cached_tokens: 10,
      })
    end
  end

  shared_examples "an erroring guardrail pipeline step" do |guardrail_name, message|
    context "when a ResponseError occurs during the call" do
      let(:guardrail_response) { nil }

      before do
        allow(Guardrails::MultipleChecker)
          .to receive(:call)
          .and_raise(
            Guardrails::MultipleChecker::ResponseError.new(
              "An error occurred", 'False | "1, 2"',
              { "prompt_tokens" => 13, "completion_tokens" => 7, "prompt_tokens_details" => { "cached_tokens" => 10 } }
            ),
          )
      end

      it "aborts the pipeline and updates the answer's status with an error message" do
        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer).to have_attributes(
          message:,
          status: "error_#{guardrail_name}",
          "#{guardrail_name}_status": "error",
          llm_responses: a_hash_including(guardrail_name => 'False | "1, 2"'),
        )
      end

      it "assigns the llm response to the answer" do
        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer.llm_responses[guardrail_name]).to eq('False | "1, 2"')
      end

      it "assigns metrics to the answer" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expect(context.answer.metrics[guardrail_name]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
          llm_cached_tokens: 10,
        })
      end
    end
  end
end
