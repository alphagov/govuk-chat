# GOV.UK Chat

**⚠️ Experimental application in early stages of development ⚠️**

A web application that provides a [LLM](https://en.wikipedia.org/wiki/Large_language_model) powered chat experience based on GOV.UK content.

## Nomenclature

- Question - an individual query from an end user
- Answer - a LLM generated response to a user's question
- Source - a reference to a chunk of GOV.UK content that was used as the supporting content for an Answer
- Conversation - a collection of questions and answers that represent a user's particular interaction with this application
- Chunk - a portion of a GOV.UK Content Item, which tends to be of the granularity of a particular heading and related content

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Before running the application

Copy the `.env.example` file to `.env` and ask a team member for the values to use.

```bash
cp .env.example .env
```

### Running the test suite

```
bundle exec rake
```

### Further documentation

- [Message queue consumption](docs/message-queue-consumption.md)
- [Populating search](docs/populating-search.md)
- [Output guardrails](docs/output_guardrails.md)

## Licence

[MIT License](LICENCE)
