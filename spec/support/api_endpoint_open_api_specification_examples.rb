module ApiEndpointOpenApiSpecificationExamples
  shared_examples "adheres to the OpenAPI specification" do |path, http_method: :get, status_code: 200|
    include Committee::Test::Methods
    let(:route_params) { [] }
    let(:params) { {} }

    it "adheres to the OpenAPI specification" do
      process(http_method, public_send(path.to_sym, *route_params), params:)
      assert_response_schema_confirm(status_code)
    end

    def request_object
      response.request
    end

    def response_data
      [response.status, response.headers, response.body]
    end

    def committee_options
      schema = Committee::Drivers.load_from_file(
        Rails.root.join("spec/support/api/openapi.yaml").to_s, parser_options: { strict_reference_validation: true }
      )

      {
        schema: schema,
        prefix: "/api/v0",
      }
    end
  end
end
