# GOV.UK Chat

A web application that provides a [LLM](https://en.wikipedia.org/wiki/Large_language_model) powered chat experience based on GOV.UK content. Initially launched as a beta with limited user access.

## Nomenclature

- Question - an individual query from an end user
- Answer - a LLM generated response to a user's question
- Source - a reference to a chunk of GOV.UK content that was used as the supporting content for an Answer
- Conversation - a collection of questions and answers that represent a user's particular interaction with this application
- Chunk - a portion of a GOV.UK Content Item, which tends to be of the granularity of a particular heading and related content
- Signon user - a user, authenticated by [signon](https://github.com/alphagov/signon), that is authenticated to use the application

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

### Before running the app

Copy the `.env.example` file to `.env` and ask a team member for the values to use.

```bash
cp .env.example .env
```

### Installing dependencies

GOV.UK Chat uses the [govuk_chat_private](https://github.com/alphagov/govuk_chat_private) gem to provide some configuration files. This gem is hosted on a private Github repo, so it needs authentication to install it.

Generate a personal access token (PAT) on Github [here](https://github.com/settings/personal-access-tokens/new). Scope the token to only allow access to the `govuk_chat_private` repo. Under the "Repository permissions" section, select "read only" under the "Contents" section.

Configure Bundler to use the PAT:

```bash
bundle config --local github.com <token>
```

You can then install the dependencies like normal.

```bash
bundle
```

### Running the test suite

```bash
bundle exec rake
```

Or can be run in govuk-docker with:

```bash
govuk-docker run govuk-chat-lite bundle exec rake
```

### Starting the app

To start the app in govuk-docker from your local machine:

```bash
bin/setup --govuk-docker
```

If you're not using govuk-docker you can run:

```bash
bin/setup
```

### Frozen OpenSearch instance

To test against the frozen OpenSearch instance, see the [govuk-chat-opensearch](https://github.com/alphagov/govuk-chat-opensearch?tab=readme-ov-file#using-the-frozen-opensearch-instance-in-the-govuk-chat-rails-app) repository.

### Further documentation

- [Message queue consumption](docs/message-queue-consumption.md)
- [Populating search](docs/populating-search.md)
- [Guardrails](docs/guardrails.md)

## Licence

[MIT License](LICENCE)
