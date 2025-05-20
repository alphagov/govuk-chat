RSpec.describe "OpenAPI Specification" do
  it "ensures that our Api specification adheres to OpenAPI V3 standards" do
    specification = Openapi3Parser.load_file("docs/api_openapi_specification.yml")
    expect(specification).to be_valid
  end
end
