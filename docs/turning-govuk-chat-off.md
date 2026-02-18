# Turning GOV.UK Chat off

## Prerequisites

In order to turn GOV.UK Chat off, you will need access to GOV.UK Chat on Signon for AWS hosted applications.

You'll also need the following permissions:

- `admin-area`
- `admin-area-settings`

The `admin-area` permission is required to access the admin interface, and the `admin-area-settings` permission is required to switch GOV.UK Chat off.

## Before you turn GOV.UK Chat off

GOV.UK Chat can be accessed via the API or web interface. Both of these can be switched off independently of each other. Once switched off, endpoints will start returning 503s (service unavailable) for all requests.

If you need to turn GOV.UK Chat off in an environment that could impact users ensure you leave a message in our [Slack channel](https://gds.slack.com/archives/C0539R9LD9P).

Here’s how switching GOV.UK Chat off for each environment could impact users.

### Production

The API is the main way users interact with GOV.UK Chat. Disabling it would **severely degrade the experience for anyone using an application that depends on it**.

The web interface is typically only turned on in production to enable departmental testing, it requires sign-on access and thus cannot be used by the general public.

### Staging

Generally, we don’t actively use Staging. However, it is occasionally used by external groups brought in to test GOV.UK Chat, for example for accessibility testing or penetration testing.

### Integration

The API is used by multiple teams across GDS. Turning it off in Integration may:

- prevent GOV.UK AI team developers from testing API endpoints
- prevent developers in teams that consume the API from using their test environments and local setups
- disrupt any demos that rely on consumer test environments

### Development

There is no imact to users. Turning off either interface in development is useful for manual testing. For example, switching off an interface and checking that the relevant endpoints return 503s.

## How to assign yourself the required permissions

If you have the super admin permission on Signon, you can grant yourself access to GOV.UK Chat here:

- [Production](https://signon.publishing.service.gov.uk/account/applications)
- [Staging](https://signon.staging.publishing.service.gov.uk/account/applications)
- [Integration](https://signon.staging.publishing.service.gov.uk/account/applications)

Once you have access, you can click the `Update permissions` link and assign yourself the `admin-area` and `admin-area-settings` permissions.

If you are not a super admin, you will need to find a GOV.UK developer who is.

## How to turn GOV.UK Chat off

This covers how to switch GOV.UK Chat off for production, but for other environments you can update the URL in step 1.

1. [visit the settings page of the admin interface](https://chat.publishing.service.gov.uk/admin/settings)
2. click the `Edit` link for `Web access` or `API access`
3. choose the `Yes` radio button
4. ensure you leave a comment for non-development environments so we have an audit trail of why chat was turned off
5. submit the form
