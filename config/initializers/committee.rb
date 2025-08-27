require "committee"
require "api/request_validation_error"

Rails.application.config.middleware.use Committee::Middleware::RequestValidation,
                                        schema_path: "docs/api_openapi_specification.yml",
                                        coerce_date_times: true,
                                        prefix: "/api/v1",
                                        strict_reference_validation: true,
                                        error_class: Api::RequestValidationError

Rails.application.config.middleware.use Committee::Middleware::ResponseValidation,
                                        schema_path: "docs/api_openapi_specification.yml",
                                        prefix: "/api/v1",
                                        strict_reference_validation: true,
                                        raise: true
