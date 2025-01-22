# 4. Open sourcing GOV.UK Chat

Date: 2025-01-22

## Context

[Point 12 of the service standard](https://www.gov.uk/service-manual/service-standard/point-12-make-new-source-code-open) is that new source code should be made open. GOV.UK Chat has previously not met that aspect of the service standard for a few reasons:

1. It was a not yet announced service that couldn't be made public 
2. There were concerns that the security impact of open sourcing prompts for Large Language Models (LLM) could impact application security
3. The content of the LLM prompts could provide a reputational risk to GDS as they provide examples of how a system should not behave which involves inflammatory Language

Since GOV.UK Chat has now [been announced to the public](https://insidegovuk.blog.gov.uk/2024/01/18/the-findings-of-our-first-generative-ai-experiment-gov-uk-chat/) the first reason no longer holds. However we have not been able to resolve the second two concerns. Indeed, during our jailbreaking testing we did indeed learn that the availability of the prompts would provide a malicious actor a significant advantage in trying to make the system misbehave.

## Decision

We have decided to partially open source the project, with all the business logic available publicly but with the LLM prompts and any configuration that provides a reputational risk remaining private.

The approach we have taken for this is to develop a RubyGem, govuk_chat_private, which remains as a private GitHub repository. While this is a relatively common technique in the Ruby ecosystem, GOV.UK does not currently have current precedence for applying this.

An alternative rejected approach was to provide this information through [application secrets](https://docs.publishing.service.gov.uk/kubernetes/manage-app/manage-secrets/), however this was not applicable as we want those secrets consistent across both dev and production envrionments and the quantity of data is quite significant (80kb).

## Status

Accepted

## Consequences

- govuk-chat will have aspects of it's configuration in a separate repository, which will:
  - require extra local developer steps to clone the repository
  - require changes to govuk-infrastructure to enable CI and deployment to operate with a private gem
  - increase difficulty in editing it and testing edits
  - require establishing a process to ensure govuk-chat is kept in sync with govuk_chat_private
- govuk-chat will have aspects of it's git history re-written to remove references to the content that is private
- The pull requests for govuk-chat will need to be removed (we will do this by creating a new repository) to remove past references to now private content, meaning aspects of history will be lost and links may become broken
- Use of a private gem is a technique with precedence in GOV.UK which other projects could adopt
- govuk-chat will be made a public repository
