module BedrockClaudeAnswerCompositionExamples
  shared_examples "a pipeline step with a configurable model" do |default_bedrock_model, other_available_models, env_var|
    describe ".bedrock_model" do
      it "defaults to using the #{default_bedrock_model} model" do
        expect(described_class.bedrock_model).to eq(default_bedrock_model)
      end

      it "allows overriding the model with the #{env_var} environment variable" do
        model = other_available_models.first.to_s
        ClimateControl.modify(env_var => model) do
          expect(described_class.bedrock_model).to eq(model)
        end
      end
    end

    other_available_models.each do |model|
      context "when the #{env_var} environment variable is set to #{model}" do
        it "uses the #{model} model" do
          ClimateControl.modify(env_var => model.to_s) do
            request = stubbed_request
            pipeline_step.call

            expect(request).to(have_been_made)
          end
        end
      end
    end
  end
end
