module BedrockClaudeAnswerCompositionExamples
  shared_examples "a claude answer composition component with a configurable model" do |env_var|
    non_default_models = described_class::SUPPORTED_MODELS - [described_class::DEFAULT_MODEL]
    describe ".bedrock_model" do
      it "defaults to using the #{described_class::DEFAULT_MODEL} model" do
        expect(described_class.bedrock_model).to eq(described_class::DEFAULT_MODEL)
      end

      it "allows overriding the model with the #{env_var} environment variable" do
        model = non_default_models.first
        ClimateControl.modify(env_var => model.to_s) do
          expect(described_class.bedrock_model).to eq(model)
        end
      end

      it "raises an error if the model specified in the #{env_var} environment variable is not supported" do
        ClimateControl.modify(env_var => "unsupported_model") do
          expect { described_class.bedrock_model }
            .to raise_error("Unsupported model for #{described_class}: unsupported_model")
        end
      end
    end

    non_default_models.each do |model|
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
