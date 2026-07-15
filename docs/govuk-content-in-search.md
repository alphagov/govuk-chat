# Which GOV.UK Content is used in Chat Search?

The configuration for which GOV.UK Content is indexed in GOV.UK Chat Search
index is in [config/search.yml](../config/search.yml).

To present a list of just the document types used we have a rake task:

```
rake search:print_document_types
```

which will output just a list of the document types, which is useful for
stakeholders who struggle with schemas.

This task can be passed an argument of ANNOTATED=true to output annotations
further config details while still anchoring the list around document types.

```
rake search:print_document_types ANNOTATED=true
```
