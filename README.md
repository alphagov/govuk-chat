# GOV.UK Chat

A web application that provides a [LLM](https://en.wikipedia.org/wiki/Large_language_model) powered chat experience based on GOV.UK content. Initially launched as a beta with limited user access.

## Nomenclature

- Question - an individual query from an end user
- Answer - a LLM generated response to a user's question
- Source - a reference to a chunk of GOV.UK content that was used as the supporting content for an Answer
- Conversation - a collection of questions and answers that represent a user's particular interaction with this application
- Chunk - a portion of a GOV.UK Content Item, which tends to be of the granularity of a particular heading and related content
- Early access user - a user that has access to use chat during the beta
- Waiting list user - a user that can't authenticate to the system and is waiting to be promoted to an Early access user
- Admin user - a user, authenticated by [signon](https://github.com/alphagov/signon), that can administer chat
- Instant access places - the number of available slots for users to register as Early access users
- Delayed access places - the number of available slots for waiting list users to be promoted to Early access users

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Before running the application

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

```
bundle
```

### Running the test suite

```
bundle exec rake
```

### Further documentation

- [Message queue consumption](docs/message-queue-consumption.md)
- [Populating search](docs/populating-search.md)
- [Guardrails](docs/guardrails.md)

## Licence

[MIT License](LICENCE)
