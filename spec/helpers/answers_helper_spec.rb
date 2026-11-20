RSpec.describe AnswersHelper do
  describe "#render_answer_message" do
    it "renders a the message inside a govspeak component" do
      output = helper.render_answer_message("Hello")
      expect(output).to have_css(".gem-c-govspeak", text: "Hello")
    end

    it "converts markdown to html" do
      output = helper.render_answer_message("## Hello world")
      expect(output).to have_css("h2", text: "Hello world")
    end

    it "does not auto convert links" do
      output = helper.render_answer_message("mailto:test@example.com")
      expect(output).to have_no_css("a")
    end

    it "handles lists without a leading double newline" do
      output = helper.render_answer_message("Some list:\n- Item 1\n- Item 2")
      expect(output).to have_css("ul > li", text: "Item 1")
      expect(output).to have_css("ul > li", text: "Item 2")
    end

    it "does not translate soft line breaks to hard line breaks" do
      output = helper.render_answer_message("Hello\nWorld")
      expect(output).to have_css(".gem-c-govspeak", text: "Hello\nWorld")
    end

    it "sanitises the message" do
      message = "<script>alert('Hello')</script>"
      output = helper.render_answer_message(message)
      expect(output).to have_no_css(".gem-c-govspeak", text: "alert")
    end
  end
end
