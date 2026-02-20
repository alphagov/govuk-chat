# Turning GOV.UK Chat off

## Prerequisites

In order to turn GOV.UK Chat off, you will need:

- access to GOV.UK Chat on Signon for AWS hosted applications
- access to the GOV.UK Heroku account for Heroku hosted applications

You'll also need the following permissions:

- `admin-area`
- `admin-area-settings`

The `admin-area` permission is required to access the admin interface, and the `admin-area-settings` permission is required to switch GOV.UK Chat off.

## Before you turn GOV.UK Chat off

GOV.UK Chat can be accessed via the API or web interface. Both of these can be switched off independently of each other. Once switched off, endpoints will start returning 503s (service unavailable) for all requests.

If you need to turn GOV.UK Chat off in an environment that could impact users ensure you leave a message in our [Slack channel](https://gds.slack.com/archives/C0539R9LD9P).

Here’s how switching off Chat for each could impact users.

### Production

The API is the primary way users interact with GOV.UK Chat. Currently, the sole consumer of the API is the GOV.UK app team. Turning off the API will **severely degrade the user experience in the app for anyone attempting to use chat**.

Currently, the web interface is not used in our production environment and should already be switched off.

### Staging

We don’t actively use Staging for testing. However, it is occasionally used by external groups brought in to test GOV.UK Chat, for example for accessibility testing or penetration testing.

### Integration

The API is used by the GOV.UK AI and GOV.UK App teams. Switching the API off on Integration may:

- block GOV.UK AI team developers from testing API endpoints
- block GOV.UK App team developers using the GOV.UK App test environment chat integration
- disrupt any demos being run by the GOV.UK App team

### Heroku

We use Heroku to host:

- a GOV.UK Chat app that uses Anthropic models for answer composition
- a GOV.UK Chat app that uses OpenAI models for answer composition
- review apps

The only one of the above that would impact users is the app that uses Anthropic models for answer composition. The web interface is used by internal team members. The API is not used.

### Development

There is no imact to users. Turning off either interface in development is useful for manual testing. For example, switching off an interface and checking that the relevant endpoints return 503s.

## How to assign yourself the required permissions

### AWS hosted environments

If you have the super admin permission on Signon, you can grant yourself access to GOV.UK Chat here:

- [Production](https://signon.publishing.service.gov.uk/account/applications)
- [Staging](https://signon.staging.publishing.service.gov.uk/account/applications)
- [Integration](https://signon.staging.publishing.service.gov.uk/account/applications)

Once you have access, you can click the `Update permissions` link and assign yourself the `admin-area` and `admin-area-settings` permissions.

If you are not a super admin, you will need to find a GOV.UK developer who is.

### Heroku and local development

The user in [/db/seeds.rb](../db/seeds.rb) already has these permissions, so you should already have access to the settings in the Admin interface. If, you don’t have access, you can add the permissions via console by running:

```
user = SignonUser.first
permissions = (user.permissions + ["admin-area", "admin-area-settings"]).uniq
user.update!(permissions:)
```

For Heroku you can find the application and access the console by:

1. signing into Heroku and navigating to [govuk-chat project](https://dashboard.heroku.com/pipelines/3ecb96c9-5336-47f1-9639-a97cf2996d21)
2. clicking on the relevant application.
3. clicking the `More` button and selecting `Run console`
4. running the above code

## How to turn GOV.UK Chat off

This covers how to switch GOV.UK Chat off for production, but for other environments you can update the URL in step 1.

1. [visit the settings page of the admin interface](https://chat.publishing.service.gov.uk/admin/settings)
2. click the `Edit` link for `Web access` or `API access`
3. choose the `Yes` radio button
4. ensure you leave a comment in the textarea for non-development environments so we have an audit trail of why chat was turned off
5. submit the form
