# Chunked content index OpenSearch seeds.

These are seed data for populating an OpenSearch index for developers.

This YAML data is created with ChatGPT (GPT-4) using the following base prompt:

```
You are a GOV.UK content designer that likes to write simple, conventional YAML.
This YAML should be based on popular GOV.UK content that is helpful and not controversial, based on your knowledge of GOV.UK and it must be in English.

The YAML should have the following attributes and be rendered in the form of a YAML array:

base_path - a simple url path based on the content
document_type - must be a value of guide, answer or transaction
title - the title of the content based on GOV.UK content
description: An optional sentence describing in the content as you would expect inside a HTML meta description tag
chunks - this must be an array objects within. This array should have between 2 and 4 items. The objects need to be in the following structure:
  html_content: HTML content within a paragraph element that relates to the GOV.UK content and is multiple sentences long at around 50 words. It must offer guidance on how a user can achieve a task. Make sure it is within a <p> element.
  heading_hierarchy: an array of strings that represent headings of the GOV.UK. Can be between 0 and 3 items - mix this up in your answer
  url: this is the base_path again but with the last item of the heading_hierachy appended as a valid URL fragment that is all lowercase. Do not have an empty fragment, if there isn't something you can link to don't put a # character

Please check your answer before replying - make sure html_content has at least 2 sentences and that each html_content varies in the number of sentences. Check the YAML is valid and put double quotes around strings that contain any non alphanumeric characters.
```

Then running individual prompts for each file of:

```
Please create a YAML array of 5 items related to <topic area>.
```

Some, but not all, YAML formatting inconsistencies were resolved by running: `npx prettier db/chunked_content_seeds/*.yml --write`
