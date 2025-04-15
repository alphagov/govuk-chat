require "committee"

Rails.application.config.middleware.use Committee::Middleware::ResponseValidation,
                                        schema_path: "spec/support/api/openapi.yaml",
                                        prefix: "/api/v0",
                                        strict_reference_validation: true
