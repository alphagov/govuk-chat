# syntax=docker/dockerfile:1

ARG ruby_version=3.4
ARG base_image=ghcr.io/alphagov/govuk-ruby-base:$ruby_version
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:$ruby_version

FROM $builder_image AS builder

ENV SECRET_KEY_BASE_DUMMY=1

WORKDIR $APP_HOME

COPY Gemfile* .ruby-version ./

RUN --mount=type=bind,target=. \
  --mount=type=secret,id=BUNDLE_GITHUB__COM,env=BUNDLE_GITHUB__COM \
  bundle install --frozen

COPY --link . .
RUN bootsnap precompile --gemfile .
RUN rails assets:precompile && rm -fr log

FROM $base_image

ENV GOVUK_APP_NAME=govuk-chat

WORKDIR $APP_HOME
COPY --from=builder --link $BUNDLE_PATH $BUNDLE_PATH
COPY --from=builder --link $BOOTSNAP_CACHE_DIR $BOOTSNAP_CACHE_DIR
COPY --from=builder --link $APP_HOME .

USER app
CMD ["puma"]
