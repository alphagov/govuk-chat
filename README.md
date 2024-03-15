# GOV.UK Chat

**⚠️ Experimental application in early stages of development ⚠️**

An web based AI assistant to integrate into GOV.UK.

## Nomenclature

Todo

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

## Licence

[MIT License](LICENCE)
