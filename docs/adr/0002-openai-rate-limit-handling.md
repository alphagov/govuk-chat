# 0002. Handling OpenAI Rate Limits within the GOV.UK Chat Application

Date: 2024-06-12

## Context
The GOV.UK Chat system currently in development utilises a 3rd party API in several aspects in order to function. This API has limitations placed upon it by the provider OpenAI. Based on our ‘tier’ of service within OpenAI, these limitations limit how many times (per minute) we can: 

1. call to ‘embed’ (to ‘embed’ in this context means to convert text into a numerical set of tokens that our own database and OpenAI can understand) and; 
2. call the LLM (Large Language Model) with our prompt (the prompt is a combination of the user’s question, our own prompt designed to tell OpenAI how to respond and in what tone, and chunks of our content retrieved from our own database.)

It is technically (though unlikely) possible to hit our rate limit on querying the LLM. In this scenario, we would not be able to respond to a user’s question and so we need to consider what we want to do in this scenario.

It should be noted, that over time as OpenAI develops their product set, these limitations will change, as will the available LLMs. Therefore, this document is likely to become less useful over time and the points highlighted below try to overcome this by being agnostic of any single limitation.

Due to SteerCo's decision, we will go-live with a closed beta to a set number of users. This will reduce the likelihood of any potential to hit our rate limits with OpenAI significantly.


## Decision
1. With this in mind, we will not automatically handle by way of the repsonse from OpenAI, how we submit questions. Instead, we will respond to any potential (though highly unlikely) rate limit by way of a crafted error message.
2. In advance of the Go Live date (TBC) and pending us entering into an Enterprise Agreement with OpenAI, we will request of OpenAI to increase our rate limit. This is a belt and braces approach. Post-Go-Live, at a time to be decided, we will request to have our rate limit reduced to normal levels.


### Rationale
In the spirit of keeping things simple, in discussions with the wider team, it was decided the risk of hitting our rate limits is so low it wasn't worth creating a mechanism to automatically respond to hitting it. Instead, we decided the appropriate response is to temporarily increase thos limits for Go Live to reduce the likelihood of us hitting them and potentially creating a reputation-damaging event.


## Status
Approved

## Consequences
Should we indeed experience a 'viral moment' or deliberate attack designed to make us hit out limits, we will need to respond manually to deactivate the application.

Another secondary consequence is that should such an event occur, we will quickly burn through our pre-paid allowance with OpenAI.

For a full Go-Live to the general public, we will develop a new feature to handle this load to minimise any user-experience impact should we hot that limit.
