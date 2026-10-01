RSpec.describe "OpenAPI Specification" do
  let(:specification) { Openapi3Parser.load_file("docs/api_openapi_specification.yml") }

  it "ensures that our Api specification adheres to OpenAPI V3 standards" do
    expect(specification).to be_valid
  end

  it "documents all available answer statuses" do
    openapi_answer_statuses = specification.components
                                           .schemas["Answer"]
                                           .properties["status"]
                                           .enum
                                           .to_a
    answer_statuses = Answer.statuses.keys

    expect(openapi_answer_statuses).to eq(answer_statuses)
  end
end
