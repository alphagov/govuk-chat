# 7. Serialisation and Schema Validation for GOV.UK Chat API

**Date:** 2025-04-15

## Context

We are building an API for GOV.UK Chat, and as part of that we need to choose tools for two concerns:

1. Serialising Ruby objects into JSON responses
2. Validating API responses against our OpenAPI specification

These tools should be simple, reliable, and maintainable, with minimal dependencies and good community support.

We want to validate that our API responses conform to the OpenAPI spec. Input validation and error formatting for requests will be handled explicitly in controller logic, but we’ll need to catch any mismatches between our responses and the schema.

## Decision

### Serialisation

We have chosen to use [Blueprinter](https://github.com/procore/blueprinter) for serializing objects into JSON. It provides a clean and lightweight way to define how data is exposed through the API.

We decided against

- **active_model_serializers**, as there are issues with maintenance and it has a history of stability issues. See:
  - https://github.com/rails-api/active_model_serializers/issues
  - https://github.com/rails-api/active_model_serializers/issues/2396
- **jsonapi-serializer**, The team has had negative experiences with it.

Blueprinter is preferred because:

- It’s simple to configure and easy to read
- It keeps response logic isolated and maintainable
- It is actively maintained and stable

### OpenAPI Response Validation

We are using [Committee](https://github.com/interagent/committee) middleware to validate that API responses match the OpenAPI 3 specification at runtime. This gives us immediate feedback if responses drift from the specification.

In addition to runtime validation, we’re also using Committee in our request specs to ensure we're checking responses conform to the schema during automated testing.

We are not using Committee to validate incoming requests, as we handle all parameter validation and error formatting in controllers to keep that logic fully under our control.

We considered [rswag](https://github.com/rswag/rswag), but opted not to use it due to:

- Its focus on documentation and Swagger UI, which isn’t a priority right now
- Its more complex setup and less intuitive behaviour for schema validation
- Committee providing simpler, targeted validation of actual responses

## Status

**accepted**

## Consequences

- Developers will use Blueprinter to define API response formats
- Response validation against the OpenAPI spec will happen at runtime via middleware, and in automated tests
- Request validation and error formatting will remain in controllers
