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

  describe "#group_used_answer_sources_by_base_path" do
    context "when there is one source per base path" do
      let(:answer) do
        create(:answer, sources: [
          create(
            :answer_source,
            base_path: "/childcare-provider",
            exact_path: "/childcare-provider/how-to-get-a-childcare-provider",
            title: "Childcare providers",
            heading: "How to get a childcare provider",
          ),
        ])
      end

      it "builds the sources using the exact path and including the heading" do
        expect(helper.group_used_answer_sources_by_base_path(answer)).to contain_exactly(
          {
            href: "#{Plek.website_root}/childcare-provider/how-to-get-a-childcare-provider",
            title: "Childcare providers: How to get a childcare provider",
          },
        )
      end

      it "filters out unused sources" do
        answer.sources << create(:answer_source, used: false, answer:)

        expect(helper.group_used_answer_sources_by_base_path(answer).length).to eq 1
      end
    end

    context "when there are multiple sources per base path" do
      let(:answer) do
        create(:answer, sources: [
          create(
            :answer_source,
            base_path: "/childcare-provider",
            exact_path: "/childcare-provider/how-to-get-a-childcare-provider",
            title: "Childcare providers",
            heading: "How to get a childcare provider",
          ),
          create(
            :answer_source,
            base_path: "/childcare-provider",
            exact_path: "/childcare-provider/how-much-it-costs",
            title: "Childcare providers",
            heading: "How much it costs",
          ),
        ])
      end

      it "builds the sources using the base path and excluding the heading" do
        expect(helper.group_used_answer_sources_by_base_path(answer)).to contain_exactly(
          {
            href: "#{Plek.website_root}/childcare-provider",
            title: "Childcare providers",
          },
        )
      end
    end
  end

  describe "#show_question_limit_system_message?" do
    it "returns false when no user is present" do
      expect(helper.show_question_limit_system_message?(nil)).to be(false)
    end

    it "returns false if the user has unlimited questions allowance" do
      user = build(:early_access_user, individual_question_limit: 0)
      expect(helper.show_question_limit_system_message?(user)).to be(false)
    end

    it "returns true if the user has reached their question limit" do
      user = build(:early_access_user, individual_question_limit: 1, questions_count: 1)
      expect(helper.show_question_limit_system_message?(user)).to be(true)
    end

    it "returns true if the user's question count is within the question warning threshold" do
      allow(Rails.configuration.conversations).to receive(:question_warning_threshold).and_return(5)

      user = build(:early_access_user, individual_question_limit: 50, questions_count: 45)
      expect(helper.show_question_limit_system_message?(user)).to be(true)
    end
  end
end
