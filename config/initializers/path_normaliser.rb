require "path_normaliser_middleware"

# This app has a number of Rack middleware's that make use of the path (Warden,
# Rack::Attack, Committee) and Rack::Attack performs path normalisation [1]
# to make the Rack path consistent with what Rails uses.
#
# This risks subtle bugs in this app as it means that middleware that runs
# before Rack::Attack may match paths different to those that run after it.
#
# To resolve this we've got our own middleware to normalise the path that we
# run before any of are other middleware with path concerns, this ensures they
# consistently have the same path value.
#
# [1]: https://github.com/rack/rack-attack/blob/467770882daa6f3865cc207c8b5dfdbc4028d7cb/lib/rack/attack.rb#L108
Rails.application.config.middleware.insert_before Warden::Manager, PathNormaliserMiddleware
