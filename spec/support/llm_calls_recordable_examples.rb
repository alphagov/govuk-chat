shared_examples "llm calls recordable" do
  describe "#assign_metrics" do
    it "updates the given namespace with the values" do
      model.assign_metrics(
        "llm_call", { duration: 1.1, llm_tokens: { prompt: 1, completion: 2 } }
      )

      expect(model.metrics).to eq(
        "llm_call" => {
          duration: 1.1,
          llm_tokens: { prompt: 1, completion: 2 },
        },
      )
    end
  end

  describe "#assign_llm_response" do
    it "updates the given namespace with the hash" do
      model.assign_llm_response(
        "llm_call", { some: "hash" }
      )

      expect(model.llm_responses).to eq(
        "llm_call" => {
          some: "hash",
        },
      )
    end
  end
end
