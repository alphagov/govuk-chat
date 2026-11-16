module GuardrailsExamples
  shared_examples "a passing guardrail pipeline step" do |guardrail_name|
    it "calls the guardrails with the answer message" do
      described_class.call(context)
      expect(AnswerComposition::MultipleGuardrail::Checker)
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
        model: BedrockModels.model_id(AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL),
      })
    end
  end

  shared_examples "a refusing guardrail pipeline step" do |guardrail_name|
    context "when Claude refuses to check the guardrails" do
      let(:guardrail_response) { nil }
      let(:llm_response) do
        claude_messages_response(
          content: [],
          stop_reason: :refusal,
          bedrock_model: AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL,
        ).to_h
      end

      before do
        allow(AnswerComposition::MultipleGuardrail::Checker)
          .to receive(:call)
          .and_raise(
            AnswerComposition::MultipleGuardrail::Checker::RefusalError.new(
              "Claude refused to check the guardrails",
              llm_response,
              nil,
              13,
              7,
              10,
              BedrockModels.model_id(AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL),
            ),
          )
      end

      it "aborts the pipeline with the refused status and message" do
        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer).to have_attributes(
          status: "unanswerable_llm_refused",
          message: Answer::CannedResponses::LLM_REFUSED_MESSAGE,
        )
      end

      it "assigns the llm response and metrics to the answer" do
        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer.llm_responses[guardrail_name]).to eq(llm_response)
        expect(context.answer.metrics[guardrail_name]).to include(llm_prompt_tokens: 13)
      end
    end
  end

  shared_examples "an erroring guardrail pipeline step" do |guardrail_name, message|
    context "when a ResponseError occurs during the call" do
      let(:guardrail_response) { nil }
      let(:llm_response) do
        claude_messages_response(
          content: "PassValue",
          bedrock_model: AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL,
        ).to_h
      end

      before do
        allow(AnswerComposition::MultipleGuardrail::Checker)
          .to receive(:call)
          .and_raise(
            AnswerComposition::MultipleGuardrail::ResponseError.new(
              "An error occurred",
              llm_response,
              'False | "1, 2"',
              13,
              7,
              10,
              BedrockModels.model_id(AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL),
            ),
          )
      end

      it "aborts the pipeline and updates the answer's status with an error message" do
        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer).to have_attributes(
          message:,
          status: "error_#{guardrail_name}",
          "#{guardrail_name}_status": "error",
        )
      end

      it "assigns the llm response to the answer" do
        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer.llm_responses[guardrail_name]).to eq(llm_response)
      end

      it "assigns metrics to the answer" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expect(context.answer.metrics[guardrail_name]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
          llm_cached_tokens: 10,
          model: BedrockModels.model_id(AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL),
        })
      end
    end
  end
end
