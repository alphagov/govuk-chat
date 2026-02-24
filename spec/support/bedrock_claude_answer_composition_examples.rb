module BedrockClaudeAnswerCompositionExamples
  shared_examples "a claude answer composition component with a configurable model" do |env_var|
    it "defaults to the #{described_class::DEFAULT_MODEL} model" do
      request = stubbed_request_lambda.call(described_class::DEFAULT_MODEL)
      pipeline_step.call
      expect(request).to(have_been_made)
    end

    it "raises an error if the #{env_var} environment variable is set to an unsupported model" do
      model_ids = BedrockModels::MODEL_IDS
      stub_const("BedrockModels::MODEL_IDS", model_ids.merge(contrived_model: "bedrock.contrived-model-1:0"))
      ClimateControl.modify(env_var => "contrived_model") do
        expect { pipeline_step.call }.to raise_error("Unsupported model: contrived_model")
      end
    end

    non_default_models = described_class::SUPPORTED_MODELS - [described_class::DEFAULT_MODEL]
    non_default_models.each do |model|
      context "when the #{env_var} environment variable is set to #{model}" do
        it "uses the #{model} model" do
          ClimateControl.modify(env_var => model.to_s) do
            request = stubbed_request_lambda.call(model)
            pipeline_step.call

            expect(request).to(have_been_made)
          end
        end
      end
    end
  end
end
