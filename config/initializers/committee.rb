require "committee"

Rails.application.config.middleware.use Committee::Middleware::ResponseValidation,
                                        schema_path: "docs/api_openapi_specification.yml",
                                        prefix: "/api/v0",
                                        strict_reference_validation: true,
                                        raise: true
