# GOV.UK Chat Guardrails

## What are guardrails

Guardrails are a means to set constraints and safeguards around a string of text. We have two kinds of guardrails: input and output.

### Input guardrails

Input guardrails safeguard text generated by a user. This might include things like determining whether the user is trying to jailbreak the system, or trying to expose the underlying prompts.

### Output guardrails

Output guardrails safeguard text generated by the LLM.

Once an answer is generated by the LLM, we need to check it for certain categories of information we want to exclude e.g. PII, advice on anything illegal, political rhetoric etc.

Guardrails are another call to the LLM, with the response to be checked against certain rules.

## Guardrails in the codebase

### JailbreakChecker

This checks the user's question to determine if it is a jailbreak attempt.

The output of the LLM is either a `1` or a `0`.

### MultipleChecker

This checks the response from the LLM against a set of guardrails.

The output of the LLM is as follows:
* `False | None` - the response is OK.
* `True | "3, 4"` - guardrails 3 and 4 were triggered

We map these to meaningful names using the mappings from a config file, e.g. [here](../config/llm_prompts/answer_guardrails.yml).

The file also contains the prompts we use to run the guardrails. Copy/paste these into the [OpenAI chat playground](https://platform.openai.com/playground/chat?models=gpt-4o) to investigate any issues.

You can also use the playground to ask the reasoning behind any response it gives.

## Printing prompts

The `guardrails:print_prompts` rake task outputs the combined system and user prompt for the answer or question routing guardrails. It takes one argument
`guardrail_type` which is the type of guardrail prompt you want to output. It must be either `answer_guardrails` or `question_routing_guardrails`.

The rake task outputs to stdout. Here is an example that outputs the answer guardrails prompt:

```
rake guardrails:print_prompts["answer_guardrails"]
```
