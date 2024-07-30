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
end
