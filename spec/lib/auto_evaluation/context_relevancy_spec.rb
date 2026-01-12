RSpec.describe AutoEvaluation::ContextRelevancy, :aws_credentials_stubbed do
  describe ".call" do
    let(:retrieval_context) do
      <<~CONTEXT
        # Context
        Page title: #{chunk.title}
        Description: #{chunk.description}
        Headings: #{chunk.heading_hierarchy.join(' > ')}
        # Content
        #{Nokogiri::HTML(chunk.html_content).text}
      CONTEXT
    end
    let(:chunk) do
      build(
        :answer_source_chunk,
        title: "Applying for Home Energy Grants",
        description: "Find out how to apply for grants",
        heading_hierarchy: %w[Overview Eligibility],
        html_content: "<p>Application processes for energy grants may vary by region</p>",
      )
    end
    let(:question) { build(:question, message: "Can I get financial help for my heating bills?") }
    let(:used_sources) do
      [build(:answer_source, used: true, chunk:)]
    end
    let(:answer) do
      build(:answer, question:, sources: used_sources)
    end
    let(:score) { 0.5 }

    let(:truths) do
      [
        {
          "context" => "Home energy grant application process",
          "facts" => [
            "Application processes for energy grants may vary by region.",
            "You should always use official channels to submit your application to avoid scams.",
          ],
        },
        {
          "context" => "Home energy grant eligibility",
          "facts" => [
            "Government grants for home energy improvements can help reduce your bills.",
            "Government grants for home energy improvements can increase your property's value.",
          ],
        },
      ]
    end
    let(:truths_json) { { truths: }.to_json }

    let(:information_needs) do
      [
        "The government schemes available to help with heating or energy bills.",
        "Eligibility criteria for receiving heating bill support.",
        "How to apply for heating bill support.",
      ]
    end
    let(:information_needs_json) { { information_needs: }.to_json }

    let(:verdicts) do
      [
        {
          "verdict" => "yes",
          "reason" => "The facts mention Government grants for home energy improvements can help reduce your bills, indicating that such government schemes exist.",
        },
        {
          "verdict" => "no",
          "reason" => "The provided facts only state that eligibility criteria can be checked on the official website.",
        },
      ]
    end
    let(:verdicts_json) { { verdicts: }.to_json }

    let(:reason) { "The score is #{score} because of some reason." }
    let(:reason_json) { { reason: }.to_json }

    let!(:context_relevancy_stubs) do
      stub_bedrock_invoke_model_openai_oss_context_relevancy(
        retrieval_context:,
        question_message: question.message,
        truths_json:,
        information_needs_json:,
        verdicts_json:,
        reason_json:,
      )
    end

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time)
                  .and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0, 212.0, 214.0)

      result = described_class.call(answer)

      expected_llm_responses = {
        truths: JSON.parse(context_relevancy_stubs[:truths].response.body),
        information_needs: JSON.parse(context_relevancy_stubs[:information_needs].response.body),
        verdicts: JSON.parse(context_relevancy_stubs[:verdicts].response.body),
        reason: JSON.parse(context_relevancy_stubs[:reason].response.body),
      }
      shared_expected_metrics_attributes = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expected_metrics = {
        truths: shared_expected_metrics_attributes,
        information_needs: shared_expected_metrics_attributes,
        verdicts: shared_expected_metrics_attributes,
        reason: shared_expected_metrics_attributes,
      }
      expect(result)
        .to be_a(AutoEvaluation::ScoreResult)
        .and have_attributes(
          score:,
          reason:,
          success: true,
          llm_responses: expected_llm_responses,
          metrics: expected_metrics,
        )
    end

    context "when 'idk' verdicts are present" do
      let(:verdicts) do
        [
          { "verdict" => "idk", "reason" => "Cannot determine if correct." },
          { "verdict" => "no", "reason" => "The provided facts only state that eligibility criteria can be checked on the official website." },
        ]
      end

      it "treats 'idk' verdicts as positive in the score" do
        result = described_class.call(answer)

        expect(result.score).to eq(0.5)
      end
    end

    context "when no sources are used in the answer generation" do
      let(:used_sources) { [] }

      it "returns a early with a maxiumum score" do
        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No sources were retrieved when generating the answer.",
            success: true,
          )
        expect(result.llm_responses.keys).to eq([])
        expect(result.metrics.keys).to eq([])
      end
    end

    context "when no information needs are extracted" do
      let(:information_needs) { [] }

      it "returns a early with a maxiumum score" do
        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No information needs were generated.",
            success: true,
          )
        expect(result.llm_responses.keys).to contain_exactly(:information_needs)
        expect(result.metrics.keys).to contain_exactly(:information_needs)
      end
    end

    context "when no truths are extracted" do
      let(:truths) { [] }

      it "returns a early with a maxiumum score" do
        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No truths were generated.",
            success: true,
          )
        expect(result.llm_responses.keys).to contain_exactly(:information_needs, :truths)
        expect(result.metrics.keys).to contain_exactly(:information_needs, :truths)
      end
    end

    context "when no verdicts are generated" do
      let(:verdicts) { [] }

      it "returns early with score 1.0 and skips the reason LLM call" do
        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No verdicts were generated.",
            success: true,
          )
        expect(result.llm_responses.keys).to contain_exactly(:truths, :information_needs, :verdicts)
        expect(result.metrics.keys).to contain_exactly(:truths, :information_needs, :verdicts)
      end
    end

    context "when score is below threshold" do
      let(:verdicts) do
        [
          { "verdict" => "no", "reason" => "Reason 1" },
          { "verdict" => "no", "reason" => "Reason 2" },
          { "verdict" => "yes", "reason" => "Reason 3" },
          { "verdict" => "no", "reason" => "Reason 4" },
        ]
      end
      let(:score) { 0.25 }

      it "returns success: false" do
        result = described_class.call(answer)

        expect(result.success).to be false
        expect(result.score).to eq(score)
      end
    end
  end
end
