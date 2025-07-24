RSpec.describe Admin::QuestionsHelper do
  let(:hidden_in_unicode_tags) { "\u{E0068}\u{E0069}\u{E0064}\u{E0064}\u{E0065}\u{E006E}" }

  describe "#format_answer_status_as_tag" do
    it "raises an error for unknown statuses" do
      expect { helper.format_answer_status_as_tag("unknown") }
        .to raise_error(RuntimeError, "Unknown status: unknown")
    end

    it "returns a valid tag for each status enum value" do
      Answer.statuses.each_value do |value|
        expect { helper.format_answer_status_as_tag(value) }.not_to raise_error
      end
    end

    context "when the status passed in does not have a corresponding description" do
      it "returns a tag with the status as the title attribute" do
        tag = helper.format_answer_status_as_tag("answered")
        expect(tag).to eq('<span title="Answered" class="govuk-tag govuk-tag--green">Answered</span>')
      end

      it "returns a tag with the status as the title attribute when with_description_suffix is true" do
        tag = helper.format_answer_status_as_tag("answered", with_description_suffix: true)
        expect(tag).to eq('<span title="Answered" class="govuk-tag govuk-tag--green">Answered</span>')
      end
    end

    context "when the status passed in has a corresponding description" do
      it "returns a tag with the status and description as the title attribute" do
        tag = helper.format_answer_status_as_tag("error_timeout")
        expect(tag).to eq('<span title="Error - no answer after configured timeout" class="govuk-tag govuk-tag--red">Error</span>')
      end

      it "returns a tag and a visible description when with_description_suffix is true" do
        tag = helper.format_answer_status_as_tag("error_timeout", with_description_suffix: true)
        expected_output = '<span title="Error - no answer after configured timeout" class="govuk-tag govuk-tag--red">Error</span>' \
                          " - no answer after configured timeout"
        expect(tag).to eq(expected_output)
      end
    end
  end

  describe "#question_show_summary_list_rows" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }

    it "returns the correct rows when question is unanswered" do
      result = helper.question_show_summary_list_rows(question, nil, 1, 1)
      expected_keys = [
        "Conversation id",
        "Question number",
        "Question id",
        "Question created at",
        "Question",
        "Show search results",
        "Source",
        "Status",
      ]

      expect(returned_keys(result)).to match_array(expected_keys)
    end

    it "returns the correct rows when the question has an answer" do
      answer = create(:answer, :with_analysis, sources: [])
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)
      expected_keys = [
        "Conversation id",
        "Question number",
        "Question id",
        "Question created at",
        "Question",
        "Show search results",
        "Source",
        "Rephrased question",
        "Status",
        "Answer created at",
        "Answer",
        "Answer strategy",
        "Jailbreak guardrails status",
        "Question routing label",
        "Question routing confidence score",
        "Question routing guardrails status",
        "Question routing guardrails triggered",
        "Answer guardrails status",
        "Answer guardrails triggered",
        "Primary topic",
        "Secondary topic",
      ]

      expect(returned_keys(result)).to eq(expected_keys)
    end

    it "returns an unsanitised question row with the sanitised section decoded and marked if the answer has an unsanitised message" do
      unsanitised_message = "Message with hidden characters #{hidden_in_unicode_tags}"
      question = create(:question, unsanitised_message:)
      answer = create(:answer)
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      row = result.find { |r| r[:field] == "Unsanitised question" }
      expect(row[:value]).to eq("ASCII smuggling decoded:<br><br>Message with hidden characters <mark>hidden</mark>")
    end

    it "returns an error message row if the answer has an error message" do
      answer = create(:answer, sources: [], error_message: "An error message")
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Error message")
    end

    it "returns a used sources row when the answer has sources" do
      answer = create(:answer, sources: [create(:answer_source)])
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Used sources")
    end

    it "returns an unused sources row when the answer has unused sources" do
      answer = create(:answer, sources: [create(:answer_source, used: false)])
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Unused sources")
    end

    it "returns feedback rows when the answer has feedback" do
      answer = create(:answer, :with_feedback)
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Feedback created at", "Feedback")
    end

    it "returns the end_user_id when present" do
      answer = answer_from_db(create(:answer))
      conversation.update!(end_user_id: "12345")
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("End user ID")
      row = result.find { |r| r[:field] == "End user ID" }
      expect(row[:value]).to include(admin_questions_path(end_user_id: "12345"))
    end

    it "returns a row with a human readable question routing label" do
      answer = create(:answer, question_routing_label: "advice_opinions_predictions")
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      row = result.find { |r| r[:field] == "Question routing label" }
      expect(row[:value]).to eq("Advice, opinions, predictions")
    end

    it "returns a row with a link to filter the questions table by the signon user" do
      signon_user = create(:signon_user)
      conversation.update!(signon_user:)
      result = helper.question_show_summary_list_rows(question, nil, 1, 1)

      row = result.find { |r| r[:field] == "Signon user" }
      expect(row[:value])
        .to include(conversation.signon_user.name)
        .and have_link(
          "View all questions",
          href: admin_questions_path(signon_user_id: conversation.signon_user.id),
        )
    end

    it "returns a row with the source of the conversation" do
      result = helper.question_show_summary_list_rows(question, nil, 1, 1)

      row = result.find { |r| r[:field] == "Source" }
      expect(row[:value]).to eq("Web")

      conversation.update!(source: :api)
      result = helper.question_show_summary_list_rows(question, nil, 1, 1)

      row = result.find { |r| r[:field] == "Source" }
      expect(row[:value]).to eq("API")
    end

    it "doesn't return a signon user row if the conversation wasn't created via the API" do
      signon_user = create(:signon_user)
      conversation.update!(signon_user:)

      result = helper.question_show_summary_list_rows(question, nil, 1, 1)
      expect(returned_keys(result)).not_to include("API user")
    end

    it "returns a row with the primary topic of the answer when present" do
      answer = create(:answer, :with_analysis)
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      row = result.find { |r| r[:field] == "Primary topic" }
      expect(row[:value]).to eq(answer.analysis.primary_topic.humanize)
    end

    it "returns a row with the secondary topic of the answer when present" do
      answer = create(:answer, :with_analysis)
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      row = result.find { |r| r[:field] == "Secondary topic" }
      expect(row[:value]).to eq(answer.analysis.secondary_topic.humanize)
    end
  end

  describe "#decode_and_mark_unicode_tag_segments" do
    context "when the input contains unicode tags" do
      it "decodes and marks the segments with unicode tags" do
        unsanitised_message = "Message with hidden characters #{hidden_in_unicode_tags}"
        decoded_and_marked_text = "Message with hidden characters <mark>hidden</mark>"
        expect(helper.decode_and_mark_unicode_tag_segments(unsanitised_message)).to eq(decoded_and_marked_text)
      end

      it "escapes any HTML in the original user message" do
        unsanitised_message = "Message with <b>hidden</b> characters #{hidden_in_unicode_tags}"
        decoded_and_marked_text = "Message with &lt;b&gt;hidden&lt;/b&gt; characters <mark>hidden</mark>"
        expect(helper.decode_and_mark_unicode_tag_segments(unsanitised_message)).to eq(decoded_and_marked_text)
      end
    end

    context "when the input does not contain unicode tags" do
      it "leaves the input unchanged" do
        input = "some normal text"
        expect(helper.decode_and_mark_unicode_tag_segments(input)).to eq("some normal text")
      end
    end
  end

  describe "#decode_unicode_tags" do
    it "decodes unicode tags characters and leaves other unchanged" do
      string_with_smuggled_chars = "Message with hidden characters #{hidden_in_unicode_tags}"
      decoded_string = "Message with hidden characters hidden"
      expect(helper.decode_unicode_tags(string_with_smuggled_chars)).to eq(decoded_string)
    end
  end

  def returned_keys(result)
    result.map { |row| row[:field] }
  end

  def answer_from_db(answer)
    Answer.includes(:sources, :feedback, :analysis).find(answer.id)
  end
end
