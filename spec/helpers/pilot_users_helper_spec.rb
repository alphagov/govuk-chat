RSpec.describe PilotUsersHelper do
  before do
    mocked_questions = Hashie::Mash.new({
      "my_question" => {
        "text" => "This is my question",
        "options" => [
          {
            "value" => "option_a",
            "text" => "Option A",
          },
          {
            "value" => "option_b",
            "text" => "Option B",
          },
        ],
      },
    })
    allow(Rails.configuration)
      .to receive(:pilot_user_research_questions)
      .and_return(mocked_questions)
  end

  describe "#user_research_question_text" do
    it "returns the text value for a question" do
      expect(helper.user_research_question_text("my_question")).to eq("This is my question")
    end

    it "can accept a symbol as the question label argument" do
      expect(helper.user_research_question_text(:my_question)).to eq("This is my question")
    end

    it "raises a KeyError when requesting a question that isn't configured" do
      expect { helper.user_research_question_text("other_question") }
        .to raise_error(KeyError)
    end
  end

  describe "#user_research_question_option_text" do
    it "returns the text value for a question option" do
      expect(helper.user_research_question_option_text("my_question", "option_a"))
        .to eq("Option A")
    end

    it "can accept symbols as arguments" do
      expect(helper.user_research_question_option_text(:my_question, :option_a))
        .to eq("Option A")
    end

    it "returns an empty string when given a nil option" do
      expect(helper.user_research_question_option_text("my_question", nil)).to eq("")
    end

    it "raises a KeyError when requesting a question that isn't configured" do
      expect { helper.user_research_question_option_text("other_question", "option_a") }
        .to raise_error(KeyError)
    end

    it "raises a RuntimeError when requesting an option that doesn't exist" do
      expect { helper.user_research_question_option_text("my_question", "option_x") }
        .to raise_error(RuntimeError, "Option option_x not found for question my_question")
    end
  end

  describe "#user_research_question_options_for_select" do
    it "returns an array of options for a select component" do
      expect(helper.user_research_question_options_for_select("my_question"))
        .to contain_exactly({ value: "", text: "", selected: false },
                            { value: "option_a", text: "Option A", selected: false },
                            { value: "option_b", text: "Option B", selected: false })
    end

    it "can accept a symbol as the question label argument" do
      expect(helper.user_research_question_options_for_select(:my_question))
        .to contain_exactly({ value: "", text: "", selected: false },
                            { value: "option_a", text: "Option A", selected: false },
                            { value: "option_b", text: "Option B", selected: false })
    end

    it "can mark an item as selected" do
      expect(helper.user_research_question_options_for_select("my_question", selected: "option_a"))
        .to contain_exactly({ value: "", text: "", selected: false },
                            { value: "option_a", text: "Option A", selected: true },
                            { value: "option_b", text: "Option B", selected: false })
    end

    it "raises a KeyError when requesting a question that isn't configured" do
      expect { helper.user_research_question_options_for_select("other_question") }
        .to raise_error(KeyError)
    end
  end

  describe "#user_research_question_items_for_radio" do
    it "returns an array of items for a radio component" do
      expect(helper.user_research_question_items_for_radio("my_question"))
        .to contain_exactly({ value: "option_a", text: "Option A", checked: false },
                            { value: "option_b", text: "Option B", checked: false })
    end

    it "can accept a symbol as the question label argument" do
      expect(helper.user_research_question_items_for_radio(:my_question))
        .to contain_exactly({ value: "option_a", text: "Option A", checked: false },
                            { value: "option_b", text: "Option B", checked: false })
    end

    it "can mark an item as checked" do
      expect(helper.user_research_question_items_for_radio(:my_question, checked: "option_b"))
        .to contain_exactly({ value: "option_a", text: "Option A", checked: false },
                            { value: "option_b", text: "Option B", checked: true })
    end

    it "raises a KeyError when requesting a question that isn't configured" do
      expect { helper.user_research_question_options_for_select("other_question") }
        .to raise_error(KeyError)
    end
  end
end
