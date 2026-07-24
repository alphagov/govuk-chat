# Resolve deprecation warning of:
#
# [DEPRECATION NOTICE] json-schema support for MultiJSON is deprecated and
# will be removed in a future version. To stop using MultiJSON, add
# `JSON::Validator.use_multi_json = false` to your application's initialization
# code.
JSON::Validator.use_multi_json = false
