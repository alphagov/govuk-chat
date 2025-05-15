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
end
