RSpec.describe AnswersHelper do
  describe "#render_answer_message" do
    it "renders a the message inside a govspeak component" do
      output = helper.render_answer_message("Hello")
      expect(output).to have_selector(".gem-c-govspeak", text: "Hello")
    end

    it "converts markdown to html" do
      output = helper.render_answer_message("## Hello world")
      expect(output).to have_selector("h2", text: "Hello world")
    end

    it "sanitises the message" do
      output = helper.render_answer_message("<script>alert('Hello')</script>")
      expect(output).to have_selector(".gem-c-govspeak", text: "alert('Hello')")
    end

    context "when skip_sanitize is true" do
      it "does not sanitize the message" do
        output = helper.render_answer_message("<a href='/' target='_blank' rel='noopener noreferrer'>Link</a>", skip_sanitize: true)
        expect(output).to have_selector("a[href='/'][target='_blank'][rel='noopener noreferrer']", text: "Link")
      end
    end
  end

  describe "#answer_combined_llm_responses" do
    it "returns an empty array if the answers llm_responses is blank" do
      answer = build(:answer, llm_responses: nil)
      expect(helper.answer_combined_llm_responses(answer)).to eq([])
    end

    it "returns nested arrays of the combined llm_responses sorted alphabetically per model" do
      analysis = build(
        :answer_analysis,
        llm_responses: {
          "topic_tagger" => "LLM response",
          "other" => "LLM response",
        },
      )
      answer = build(
        :answer,
        llm_responses: {
          "structured_answer" => "LLM response",
          "jailbreak_guardrails" => "LLM response",
        },
        analysis:,
      )

      expected_result = [
        ["jailbreak_guardrails", "LLM response"],
        ["structured_answer", "LLM response"],
        ["other", "LLM response"],
        ["topic_tagger", "LLM response"],
      ]
      expect(helper.answer_combined_llm_responses(answer)).to eq(expected_result)
    end

    it "only returns the answer llm_responses if there is no analysis" do
      answer = build(
        :answer,
        llm_responses: {
          "structured_answer" => "LLM response",
          "jailbreak_guardrails" => "LLM response",
        },
      )

      expected_result = [
        ["jailbreak_guardrails", "LLM response"],
        ["structured_answer", "LLM response"],
      ]
      expect(helper.answer_combined_llm_responses(answer)).to eq(expected_result)
    end
  end

  describe "#answer_combined_metrics" do
    it "returns an empty hash if the answer metrics is blank" do
      answer = build(:answer, metrics: nil)
      expect(helper.answer_combined_metrics(answer)).to eq({})
    end

    it "returns the combined metrics of the answer and its analysis" do
      analysis = build(
        :answer_analysis,
        metrics: {
          "topic_tagger" => { "duration" => 1.5, "llm_prompt_tokens" => 30 },
          "other" => { "duration" => 2.0, "llm_prompt_tokens" => 40 },
        },
      )
      answer = build(
        :answer,
        metrics: {
          "structured_answer" => { "duration" => 3.0, "llm_prompt_tokens" => 50 },
          "jailbreak_guardrails" => { "duration" => 4.0, "llm_prompt_tokens" => 60 },
        },
        analysis: analysis,
      )

      expected_result = {
        "jailbreak_guardrails" => { "duration" => 4.0, "llm_prompt_tokens" => 60 },
        "structured_answer" => { "duration" => 3.0, "llm_prompt_tokens" => 50 },
        "other" => { "duration" => 2.0, "llm_prompt_tokens" => 40 },
        "topic_tagger" => { "duration" => 1.5, "llm_prompt_tokens" => 30 },
      }
      expect(helper.answer_combined_metrics(answer)).to eq(expected_result)
    end

    it "returns only the answer metrics if there is no analysis" do
      answer = build(
        :answer,
        metrics: {
          "structured_answer" => { "duration" => 3.0, "llm_prompt_tokens" => 50 },
          "jailbreak_guardrails" => { "duration" => 4.0, "llm_prompt_tokens" => 60 },
        },
      )

      expected_result = {
        "jailbreak_guardrails" => { "duration" => 4.0, "llm_prompt_tokens" => 60 },
        "structured_answer" => { "duration" => 3.0, "llm_prompt_tokens" => 50 },
      }
      expect(helper.answer_combined_metrics(answer)).to eq(expected_result)
    end
  end
end
