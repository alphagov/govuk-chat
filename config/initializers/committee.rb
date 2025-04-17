require "committee"

Rails.application.config.middleware.use Committee::Middleware::ResponseValidation,
                                        schema_path: "spec/support/api/govuk_chat_api_specification.yaml",
                                        prefix: "/api/v0",
                                        strict_reference_validation: true,
                                        raise: true
